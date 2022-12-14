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

local function main(port)
  package.loaded[modname] = nil

  local port = port or require("device_settings", "http_srv").port or 80
  local srv = {
    routes = {},
    srv = nil
  }
  require("log").info("starting http server on port " .. p)
  srv.srv = net.createServer(net.TCP, 30)
  srv.srv:listen(p, listenFn)
  return srv
end

return main
