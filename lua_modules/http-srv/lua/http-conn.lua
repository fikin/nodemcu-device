--[[
  Process a new http connection
]]

--- global counter for open connections
OpenConnectionsCnt = 0

---@alias str_fn fun():string|nil
---@alias conn_gc_fn fun(wasOk: boolean)

---@alias conn_handler_fn fun(conn: http_conn*)
---@alias conn_routes {[string]:conn_handler_fn}

local modname = ...

local log = require("log")

local function pcallgc(fnc, ...)
  local ok, err = pcall(fnc, ...)
  collectgarbage()
  collectgarbage()
  return ok, err
end

---factory for function which is bound to connection() callback, it simply logs it
---@return socket_fn function bound to the connection
local function auditConnFn()
  return function(sk)
    local remotePort, remoteIp = sk:getpeer()
    log.audit("accepted connection from %s:%d", remoteIp, remotePort)
  end
end

---factory for function which is bound to reconnection() callback, it simply logs it
---@return socket_fn function bound to the connection
local function traceReconnFn()
  return function(sk, err)
    local remotePort, remoteIp = sk:getpeer()
    log.debug("reconnection from %s:%d %s", remoteIp, remotePort, err)
  end
end

---factory for function which is bound to disconnect() callback, it gc the connection
---@param conn http_conn*
---@return socket_fn function bound to the connection
local function disconnectedConnFn(conn)
  return function(sk, err)
    local p, i = sk:getpeer()
    log.audit("client disconnected %s:%d : %s", i, p, err)
    require("http-conn-gc")(conn, err ~= nil)
  end
end

---factory for function which is bound to receive() callback,
---it collects the data into buffer and resumes the coroutine
---@param conn http_conn*
---@return socket_fn function bound to the connection
local function receivingFn(conn)
  return function(sk, data)
    if data then
      conn.buffer = conn.buffer .. data
      conn.req.isEOF = false
    else
      conn.req.isEOF = true
    end
    coroutine.resume(conn.co)
  end
end

---factory for function which is bound to sent() callback, it resumes the coroutine
---@param conn http_conn*
---@return socket_fn function bound to the connection
local function sendingFn(conn)
  return function(sk)
    coroutine.resume(conn.co)
  end
end

---coverts error string to http response code
---it recognizes text in the form "<code>: text"
---@param err string
---@return string code
---@return string message or error
local function errToCode(err)
  local _, _, code, msg = string.find(err, ".*%s(%d+): (.*)")
  if code then
    return code, msg
  end
  return "500", err
end

---logs error
---@param log logger
---@param conn http_conn*
---@param msg string
---@param err any
---@return string text json of the error
local function logErrMsg(log, conn, msg, err)
  local remoteIp, remotePort = conn.sk:getpeer()
  local method, url = conn.req.method, conn.req.url
  local o = { host = remoteIp, port = remotePort, method = method, url = url, msg = msg, err = err }
  return log.json(o)
end

---finds route handling this url and runs it
---returns false and error in case of missing route or internal failure
---@param conn http_conn*
---@param webModules string[] list of web modules serving http routes
---@return boolean flag indicating if pcall handling the route executed ok
local function handleRoute(conn, webModules)
  for _, mod in ipairs(webModules) do
    -- modules return true if they handled the route
    local ok = require(mod)(conn)
    if ok then
      return ok
    end
  end
  error("404: no router defind handling %s" % conn.req.url)
end

---called at connection GC to decrease global open connections counter
---@param isOk any
local function decConnCnt(isOk)
  if OpenConnectionsCnt > 0 then
    OpenConnectionsCnt = OpenConnectionsCnt - 1
  end
end

---@param conn http_conn*
local function concurrent(conn)
  if OpenConnectionsCnt > 0 then
    return false, "429: too many connections"
  end
  OpenConnectionsCnt = OpenConnectionsCnt + 1
  table.insert(conn.onGcFn, decConnCnt)
  return true, nil
end

---@param conn http_conn*
---@param err string
local function closeConn(conn, err)
  local p, i = conn.sk:getpeer()
  log.audit("closing client %s:%d", i, p)
  conn.sk:close()
  require("http-conn-gc")(conn, err ~= nil)
end

---read http request and finds route to handle it
---if no route exists, it returns 404
---@param conn http_conn*
---@param webModules string[] list of web-modules serving routes
---@return fun() coroutine function to call
local function handleReq(conn, webModules)
  return function()
    local ok, err = concurrent(conn)
    if ok then
      ok, err = pcallgc(require("http-conn-req"), conn)
    end
    if ok then
      ok, err = pcallgc(handleRoute, conn, webModules)
    end
    if not ok then
      conn.resp.code, conn.resp.body = errToCode(err)
      log.error(logErrMsg(log, conn, "processing request", err))
    end
    log.info("%s %s -> %s", conn.req.method, conn.req.url, conn.resp.code)
    ok, err = pcallgc(require("http-conn-resp"), conn)
    if not ok then
      log.error(logErrMsg(log, conn, "writing response", err))
    end
    closeConn(conn, err)
  end
end

---instantiates new http connection
---@param sk socket
---@return http_conn*
local function defaultConn(sk)
  ---@class http_conn*
  local o = {
    ---@type socket
    sk = sk,
    ---@type thread
    co = nil,
    ---@type string
    buffer = "",
    ---@class http_req*
    req = {
      method = "",
      url = "",
      ---@type {[string]:string}
      headers = {},
      ---@type str_fn
      body = nil,
      ---@type boolean
      isEOF = false,
    },
    ---@class http_resp*
    resp = {
      code = "",
      ---@type {[string]:string|number}
      headers = {},
      ---@type str_fn|string|string[]|nil
      body = nil
    },
    ---@type conn_gc_fn[]
    onGcFn = {}
  }
  return o
end

---handles a net connection
---@param sk socket
---@param webModules string[] list of web modules serving http routes
local function main(sk, webModules)
  package.loaded[modname] = nil

  local conn = defaultConn(sk)

  conn.co = coroutine.create(handleReq(conn, webModules))
  sk:on("connection", auditConnFn())
  sk:on("reconnection", traceReconnFn())
  sk:on("disconnection", disconnectedConnFn(conn))
  sk:on("receive", receivingFn(conn))
  sk:on("sent", sendingFn(conn))
end

return main
