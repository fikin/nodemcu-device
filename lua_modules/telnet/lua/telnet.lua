--[[
  A telnet server.

  It supports only 1 telnet session, otherwise node.output and input get messed up.

  It is based on lua_modules/telnet/telnet.lua.

  Depends on: node, net, log
]]
--

local modname = ...

local node = require("node")
local log = require("log")

---@class telnet_cfg
---@field port integer
---@field timeoutSec integer
---@field usr string
---@field pwd string

---@class telnet_state
---@field lastLogingTs string

---@return telnet_cfg
local function getSettings()
  return require("device-settings")(modname)
end

---@return telnet_state
local function getState()
  return require("state")(modname)
end

local cfg = getSettings()
local usr, pwd = cfg.usr, cfg.pwd

local stdout = nil -- TODO defining it here used to break telnet in past.
-- check it again? adding it now due to linter ...

---called when connection is closed to restore node's std streams
local function onDisconnect()
  log.audit("telnet session closed")
  node.output()
  stdout = nil
end

---pass incoming socket data to node's input
---this is net.tcp.socket.receiving callback
---@param _ socket
---@param data string
local function onReceiving(_, data)
  node.input(data)
end

---called initial time to pipe first stdout data to the socket
---@param tbl table containing "pipe":tools_pipe
---@return fun(skt:socket)
local function readAndSendOnceFact(tbl)
  return function(skt)
    local rec = tbl.pipe:read(1400)
    if rec and #rec > 0 then
      if not pcall(function() skt:send(rec) end) then
        pcall(function() skt:close() end)
        onDisconnect()
      end
    end
  end
end

---audit logging of new connection
---@param skt socket
local function logNewConnection(skt)
  local port, ip = skt:getpeer()
  log.audit("incomming connection from %s", log.json, { port = port, ip = ip })
end

---@param _ socket
local function welcomeMsg(_)
  log.info("Welcome to NodeMCU")
  collectgarbage()
  collectgarbage()
  log.info("%d mem free", node.heap())
  local state = getState()
  local ts = require("get-timestamp")()
  log.info("Last login: %s", state.lastLogingTs or ts)
  state.lastLogingTs = ts
end

---redirects node std streams to the socket
---@param skt socket
local function openNodeSession(skt)
  -- pipe provided by node.output
  stdout = {} -- TODO used to be "local"-defined here. check comment at beginning.

  local readAndSendOnce = readAndSendOnceFact(stdout)

  local function firstWrite(opipe)
    stdout.pipe = opipe
    readAndSendOnce(skt)
    return false -- don't repost as the on:sent will do this
  end

  node.output(firstWrite, 0)
  skt:on("receive", onReceiving)
  skt:on("sent", readAndSendOnce)
  skt:on("disconnection", onDisconnect)
  welcomeMsg(skt)
end

---normalizes line of data coming from socket
---@param data string
---@return string line
---@return integer count
local function readLine(data)
  return string.gsub(data, "^%s*(.-)%s*$", "%1")
end

---@type socket_fn
local askUsr

---@param skt socket
---@param data string
local function onAuthenticated(skt, data)
  if readLine(data) == pwd then
    log.audit("telnet session open for user %s", usr)
    -- TODO last login info
    openNodeSession(skt)
  else
    askUsr(skt)
  end
end

---@param skt socket
---@param data string
local function askPwd(skt, data)
  if readLine(data) == usr then
    skt:send("Enter password:")
    skt:on("receive", onAuthenticated)
  else
    askUsr(skt)
  end
end

---@param skt socket
---@param _ string
askUsr = function(skt, _)
  skt:send("Enter username:")
  skt:on("receive", askPwd)
end

---@param skt socket
local function authenticate(skt)
  skt:on("sent", nil)
  skt:on("disconnection", onDisconnect)
  askUsr(skt)
end

---sends already connected message
---@param skt socket
local function alreadyConnected(skt)
  skt:send(
    "telnet session already open, aborting.",
    function(sk) sk:close() end
  )
end

---handle new telnet connection.
---allows only 1 ongoing telnet connection
---@param skt socket
local function onNewConnection(skt)
  logNewConnection(skt)

  if stdout then
    alreadyConnected(skt)
    return
  end

  authenticate(skt)
end

---start up telnet server
---@return tcpServer
local function startup()
  local net = require("net")
  local srv = net.createServer(cfg.timeoutSec)
  srv:listen(cfg.port, onNewConnection)
  log.info("listening on port %d", cfg.port)
  return srv
end

---creates telnet server
---@return table a net.tcp.server
local function main()
  package.loaded[modname] = nil

  return startup()
end

return main
