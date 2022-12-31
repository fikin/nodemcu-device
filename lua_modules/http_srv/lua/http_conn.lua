--[[
  Process a new http connection
]]
local modname = ...

---@alias str_fn fun():string
---@alias conn_gc_fn fun(wasOk: boolean)

---@class http_req*
---@field method string
---@field url string
---@field headers string
---@field body str_fn

---@class http_resp*
---@field code string
---@field headers table
---@field body str_fn|string|table

---@class http_conn*
---@field sk table net.tcp.connection object
---@field co thread coroutine function handling the request
---@field buffer string collects currently read data from the socket
---@field req http_req*
---@field resp http_resp*
---@field onGcFn conn_gc_fn[] called to gc connection resources

---@alias conn_handler_fn fun(conn: http_conn*)
---@alias conn_routes table<string,conn_handler_fn>

---factory for function which is bound to connection() callback, it simply logs it
---@return fun(skt: table):nil bound to the connection
local function auditConnFn()
  return function(sk)
    local remoteIp, remotePort = sk:getpeer()
    require("log").audit("accepted connection from", remoteIp, remotePort)
  end
end

---factory for function which is bound to reconnection() callback, it simply logs it
---@return fun(skt: table, err: string):nil bound to the connection
local function traceReconnFn()
  return function(sk, err)
    local remoteIp, remotePort = sk:getpeer()
    require("log").debug("reconnection from", remoteIp, remotePort, err)
  end
end

---factory for function which is bound to disconnect() callback, it gc the connection
---@param conn http_conn*
---@return fun(skt: table, err: string):nil bound to the connection
local function disconnectedConnFn(conn)
  return function(sk, err)
    require("log").audit("client disconnected", err)
    require("http_conn_gc")(conn, err ~= nil)
  end
end

---factory for function which is bound to receive() callback,
---it collects the data into buffer and resumes the coroutine
---@param conn http_conn*
---@return fun(skt: table,data: string):nil bound to the connection
local function receivingFn(conn)
  return function(sk, data)
    conn.buffer = conn.buffer .. data
    coroutine.resume(conn.co)
  end
end

---factory for function which is bound to sent() callback, it resumes the coroutine
---@param conn http_conn*
---@return fun(skt: table):nil bound to the connection
local function sendingFn(conn)
  return function(sk)
    coroutine.resume(conn.co)
  end
end

---find the route handling this url request or nil
---@param conn http_conn*
---@return boolean true if executed ok
---@return conn_handler_fn|nil
---@return string|nil
local function findRoute(conn)
  local ok, o = pcall(require("http_routes").findRoute, conn.req.method, conn.req.url)
  if ok then
    return ok, o, nil
  end
  return ok, nil, string(o)
end

---coverts error string to http response code
---it recognizes text in the form "<code>: text"
---@param err string
---@return string
---@return string
local function errToCode(err)
  local _, _, code, msg = string.find(string(err), ".*%s(%d+): (.*)")
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
---@return string
local function logErrMsg(log, conn, msg, err)
  local remoteIp, remotePort = conn.sk:getpeer()
  local method, url = conn.req.method, conn.req.url
  local o = { host = remoteIp, port = remotePort, method = method, url = url, msg = msg, err = err }
  return log.json(o)
end

---finds route handling this url and runs it
---returns false and error in case of missing route or internal failure
---@param conn http_conn*
---@return boolean
---@return string|nil
local function handleRoute(conn)
  local ok, hFn, err = findRoute(conn)
  if ok and hFn then
    ok, err = pcall(hFn, conn)
  end
  return ok, err
end

---read http request and finds route to handle it
---if no route exists, it returns 404
---@param conn http_conn*
---@return fun() coroutine function to call
local function handleReq(conn)
  return function()
    local log = require("log")

    local ok, err = pcall(require("http_conn_req"), conn)
    if ok then
      ok, err = handleRoute(conn)
    end
    if not ok then
      conn.resp.code, conn.resp.body = errToCode(string(err))
      log.error(logErrMsg(log, conn, "processing request", err))
    end
    ok, err = pcall(require("http_conn_resp"), conn)
    if not ok then
      log.error(logErrMsg(log, conn, "writing response", err))
    end
    require("http_conn_gc")(conn, ok)
  end
end

---instantiates new http connection
---@param sk table
---@return http_conn*
local function defaultConn(sk)
  return {
    sk = sk,
    co = nil,
    buffer = "",
    req = {
      method = "",
      url = "",
      headers = {},
      body = nil
    },
    resp = {
      code = "",
      headers = {},
      body = nil
    },
    onGcFn = {}
  }
end

---handles a net connection
---@param sk any
local function main(sk)
  package.loaded[modname] = nil

  local conn = defaultConn(sk)

  conn.co = coroutine.create(handleReq(conn))
  sk:on("connection", auditConnFn())
  sk:on("reconnection", traceReconnFn())
  sk:on("disconnection", disconnectedConnFn(conn))
  sk:on("receive", receivingFn(conn))
  sk:on("sent", sendingFn(conn))
end

return main
