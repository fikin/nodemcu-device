--[[  
  A telnet server.

  It supports only 1 telnet session, otherwise node.output and input get messed up.

  It is based on lua_modules/telnet/telnet.lua.

  Depends on: node, net, log
]] --

local modname = ...

local node = require("node")
local log = require("log")

local cfg = require("device_settings").telnet

-- pipe provided by node.output
local stdout = nil

local function onDisconnect()
  log.audit("telnet session closed")
  node.output()
  stdout = nil
end

local function onReceiving(_, data)
  node.input(data)
end

local function readAndSendOnce(conn)
  local rec = stdout:read(1400)
  if rec and #rec > 0 then
    conn:send(rec)
  end
end

local function logNewConnection(conn)
  local port, ip = conn:getpeer()
  log.audit("incomming connection from %s", log.json, {port = port, ip = ip})
end

local function openNodeSession(conn)
  local function firstWrite(opipe)
    stdout = opipe
    readAndSendOnce(conn)
    return false -- don't repost as the on:sent will do this
  end

  node.output(firstWrite, 0)
  conn:on("receive", onReceiving)
  conn:on("sent", readAndSendOnce)
  conn:on("disconnection", onDisconnect)
  log.info(("Welcome to NodeMCU world (%d mem free)"):format(node.heap()))
end

local function authenticate(conn)
  local state = 1 -- 1=username, 2=password
  local function doState()
    if state == 2 then
      conn:send("Enter password:")
    elseif state == 3 then
      log.audit("telnet session open for user %s" % cfg.usr)
      openNodeSession(conn)
    else
      conn:send("Enter username:")
    end
  end
  conn:on(
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
  conn:on(
    "sent",
    function()
    end
  )
  conn:on(
    "disconnection",
    function()
    end
  )
end

local function onNewConnection(conn)
  logNewConnection(conn)

  if stdout then
    conn:send(
      "telnet session already open, aborting.",
      function(sk)
        sk:close()
      end
    )
    return
  end

  authenticate(conn)
end

local function main(port)
  package.loaded[modname] = nil

  local net = require("net")
  port = port or cfg.port
  local svr = net.createServer(net.TCP, 180)
  svr:listen(port or 23, onNewConnection)
  log.info(modname, "listening on port", port)
  return srv
end

return main
