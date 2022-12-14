--[[
  Process a new http connection
]]
local modname = ...

local function auditConnFn()
  return function(sk)
    local remoteIp, remotePort = sk:getpeer()
    require("log").audit("accepted connection from", remoteIp, remotePort)
  end
end

local function traceReconnFn()
  return function(sk, err)
    local remoteIp, remotePort = sk:getpeer()
    require("log").debug("reconnection from", remoteIp, remotePort, err)
  end
end

local function disconnectedConnFn(conn)
  return function(sk, err)
    require("log").audit("client disconnected", err)
    require("http_conn_gc")(conn, err ~= nil)
  end
end

local function receivingFn(conn)
  return function(sk, data)
    conn.buffer = conn.buffer .. data
    coroutine.resume(conn.co)
  end
end

local function sendingFn(conn, clearSkFn)
  return function(sk)
    coroutine.resume(conn.co)
  end
end

local function handleReq(conn)
  return function()
    local log = require("log")

    local function errToCode(err)
      local _, _, code, msg = string.find(err, ".*%s(%d+): (.*)")
      if code then
        return code, msg
      end
      return "500", err
    end

    local function logErrMsg(conn, msg, err)
      local remoteIp, remotePort = conn.sk:getpeer()
      local method, url = conn.req.method, conn.req.url
      local o = {host = remoteIp, port = remotePort, method = method, url = url, msg = msg, err = err}
      return log.json(o)
    end

    local ok, err = pcall(require("http_conn_req"), conn)
    if ok then
      ok, err = pcall(require("http_routes").findRoute, conn.req.method, conn.req.url)
    end
    if not ok then
      conn.resp.code, conn.resp.body = errToCode(err)
      log.error(logErrMsg(conn, "processing request", err))
    end
    ok, err = pcall(require("http_conn_resp"), conn)
    if not ok then
      log.error(logErrMsg(conn, "writing response", err))
    end
    require("http_conn_gc")(conn, ok)
  end
end

local function defaultConn()
  return {
    sk = sk,
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

local function main(sk)
  package.loaded[modname] = nil

  local conn = defaultConn()

  conn.co = coroutine.create(handleReq(conn))
  sk:on("connection", auditConnFn())
  sk:on("reconnection", traceReconnFn())
  sk:on("disconnection", disconnectedConnFn(conn))
  sk:on("receive", receivingFn(conn))
  sk:on("sent", sendingFn(conn))
end

return main
