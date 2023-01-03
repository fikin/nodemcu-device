--[[  
  A telnet server.

  It supports only 1 telnet session, otherwise node.output and input get messed up.

  It is based on lua_modules/telnet/telnet.lua.

  Depends on: node, net, log
]] --

local modname = ...

local node = require("node")
local log = require("log")

---@class telnet_cfg
---@field port integer
---@field timeoutSec integer
---@field ip? string
---@field usr string
---@field pwd string
local cfg = require("device-settings")(modname)

-- pipe provided by node.output
local stdout = nil

---called when connection is closed to restore node's std streams
local function onDisconnect()
  log.audit("telnet session closed")
  node.output()
  stdout = nil
end

---pass incoming socket data to node's input
---this is net.tcp.socket.receiving callback
---@param _ table is net.tcp.socket
---@param data string
local function onReceiving(_, data)
  node.input(data)
end

---called initial time to pipe first stdout data to the socket
---@param skt any
local function readAndSendOnce(skt)
  local rec = stdout:read(1400)
  if rec and #rec > 0 then
    skt:send(rec)
  end
end

---audit logging of new connection
---@param skt table is net.tcp.socket
local function logNewConnection(skt)
  local port, ip = skt:getpeer()
  log.audit("incomming connection from %s", log.json, { port = port, ip = ip })
end

---redirects node std streams to the socket
---@param skt table is net.tcp.socket
local function openNodeSession(skt)
  local function firstWrite(opipe)
    stdout = opipe
    readAndSendOnce(skt)
    return false -- don't repost as the on:sent will do this
  end

  node.output(firstWrite, 0)
  skt:on("receive", onReceiving)
  skt:on("sent", readAndSendOnce)
  skt:on("disconnection", onDisconnect)
  log.info(("Welcome to NodeMCU world (%d mem free)"):format(node.heap()))
end

---asks user name and password from the telnet client
---@param skt table is net.tcp.socket
local function authenticate(skt)
  local state = 1 -- 1=username, 2=password
  local function doState()
    if state == 2 then
      skt:send("Enter password:")
    elseif state == 3 then
      log.audit("telnet session open for user %s" % cfg.usr)
      openNodeSession(skt)
    else
      skt:send("Enter username:")
    end
  end

  skt:on(
    "receive",
    function(_, data)
      data = string.gsub(data, "^%s*(.-)%s*$", "%1")
      if state == 1 then
        state = data == cfg.usr and 2 or 1
      elseif state == 2 then
        state = data == cfg.pwd and 3 or 1
      end
      doState()
    end
  )
  skt:on(
    "sent",
    function()
    end
  )
  skt:on(
    "disconnection",
    function()
    end
  )
end

---handle new telnet connection.
---allows only 1 ongoing telnet connection
---@param skt table net.tcp.socket
local function onNewConnection(skt)
  logNewConnection(skt)

  if stdout then
    skt:send(
      "telnet session already open, aborting.",
      function(sk)
        sk:close()
      end
    )
    return
  end

  authenticate(skt)
end

---creates telnet server
---@param port? integer
---@return table a net.tcp.server
local function main(port)
  package.loaded[modname] = nil

  local net = require("net")
  local srv = net.createServer(cfg.timeoutSec)
  srv:listen(cfg.port, cfg.ip, onNewConnection)
  log.info(modname, string.format("listening on port %d", cfg.port))
  return srv
end

return main
