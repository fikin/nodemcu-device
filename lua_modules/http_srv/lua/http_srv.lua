--[[
  HTTP server.

  local s = require("http_srv")(80)

  require("http_routes").setPath("GET", "/", function(conn) require("http_return_file")(conn, "index.html") end)
  ...
]]
local modname = ...

local function listenFn(sk)
  require("http_conn")(sk)
end

---creates tcp server and binds the listener function to it
---@param port? integer
---@return table net.tcp.server object
local function main(port)
  package.loaded[modname] = nil

  local port = port or require("device_settings")("http_srv").port or 80
  require("log").info("starting http server on port " .. port)
  local net = require("net")
  local srv = net.createServer(net.TCP, 30)
  srv:listen(port, listenFn)
  return srv
end

return main
