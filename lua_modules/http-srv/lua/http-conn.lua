--[[
  Process a new http connection
]]
---@alias str_fn fun():string|nil
---@alias conn_gc_fn fun(wasOk: boolean)

---@alias conn_handler_fn fun(conn: http_conn*)
---@alias conn_routes {[string]:conn_handler_fn}

---@class http_req*
---@field method string
---@field url string
---@field headers {[string]:string}
---@field body str_fn|nil
---@field isEOF boolean

---@class http_resp*
---@field code string
---@field headers {[string]:string|number}
---@field body str_fn|string|string[]|nil

---@class http_conn*
---@field sk socket
---@field co thread|nil
---@field buffer string
---@field req http_req*
---@field resp http_resp*
---@field onGcFn conn_gc_fn[]


local modname = ...

local log = require("log")
local tmr = require("tmr")

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
    local remotePort, remoteIp = pcall(function() return sk:getpeer(); end)
    log.audit("accepted connection from %s:%s", remoteIp, tostring(remotePort))
  end
end

---factory for function which is bound to reconnection() callback, it simply logs it
---@param conn http_conn*
---@return socket_fn function bound to the connection
local function onReconnFn(conn)
  return function(sk, err)
    local remotePort, remoteIp = pcall(function() return sk:getpeer(); end)
    log.debug("reconnection from %s:%s %s", tostring(remoteIp), tostring(remotePort), err)
    coroutine.resume(conn.co)
  end
end

---factory for function which is bound to disconnect() callback, it gc the connection
---@param conn http_conn*
---@return socket_fn function bound to the connection
local function disconnectedConnFn(conn)
  return function(sk, err)
    local p, i = sk:getpeer()
    log.audit("client disconnected %s:%d : %s", i, p or 0, err)
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
  local _, _, _, _, code, msg = string.find(err, "(.*):(%d+): (%d+): (.*)")
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
  local remoteIp, remotePort = pcall(function() return conn.sk:getpeer(); end)
  local method, url = conn.req.method, conn.req.url
  local o = { host = remoteIp, port = remotePort, method = method, url = url, msg = msg, err = err }
  return log.json(o)
end

---finds route handling this url and runs it
---@param conn http_conn*
---@param webModules string[] list of web modules serving http routes
local function handleRoute(conn, webModules)
  for _, mod in ipairs(webModules) do
    -- modules return true if they handled the route
    local ok = require(mod)(conn)
    if ok then
      return
    end
  end
  error("404: router has no mapping for %s %s" % { conn.req.method, conn.req.url })
end

---read peer data safely
---@param conn http_conn*
---@return string
local function getPeer(conn)
  local str = "<socket closed>:0"
  local ok, p, i = pcall(function() return conn.sk:getpeer(); end)
  if ok then
    str = tostring(i) .. ":" .. tostring(p)
  end
  return str
end

---@param conn http_conn*
---@param err string|nil
local function closeConn(conn, err)
  local str = getPeer(conn)
  if err then
    log.error("internal error while processing : %s : %s", str, err)
  end
  log.audit("closing client %s", str)
  require("http-conn-gc")(conn, err ~= nil)
end

---assigns response status in case there is error
---@param conn http_conn*
---@param ok boolean
---@param err string
local function prepareRespInCaseOfError(conn, ok, err)
  if not ok then
    conn.resp.code, conn.resp.body = errToCode(tostring(err))
    log.error(logErrMsg(log, conn, "processing request", err))
  end
end

---actual handler of requests
---@param webModules string[]
---@param conn http_conn*
local function doHandleReq(webModules, conn)
  local ok, err = pcallgc(require("http-conn-req"), conn)
  if ok then
    ok, err = pcallgc(handleRoute, conn, webModules)
  end
  prepareRespInCaseOfError(conn, ok, err)
  log.info("%s %s -> %s", conn.req.method, conn.req.url, conn.resp.code)
  ok, err = pcallgc(require("http-conn-resp"), conn)
  if not ok then
    log.error(logErrMsg(log, conn, "writing response", err))
  end
end

---read http request and finds route to handle it
---@param conn http_conn*
---@param webModules string[] list of web-modules serving routes
---@return fun() coroutine function to call
local function handleReq(conn, webModules)
  return function()
    local _, ok, err = pcall(doHandleReq, webModules, conn)
    closeConn(conn, ok and err or nil)
  end
end

---instantiates new http connection
---@param sk socket
---@return http_conn*
local function defaultConn(sk)
  ---@type http_conn*
  local o = {
    sk = sk,
    co = nil,
    buffer = "",
    req = {
      method = "",
      url = "",
      headers = {},
      body = nil,
      isEOF = false,
    },
    resp = {
      code = "",
      headers = {},
      body = nil
    },
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
  sk:on("reconnection", onReconnFn(conn))
  sk:on("disconnection", disconnectedConnFn(conn))
  sk:on("receive", receivingFn(conn))
  sk:on("sent", sendingFn(conn))
end

return main
