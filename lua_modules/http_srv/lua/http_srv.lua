--[[
  HTTP server.

  local s = require("http_srv")(80)
  s.routes["GET /"] = function(conn) require("http_return_file")(conn, "index.html") end
  ...
]]
local modname = ...

local function listenFn(srv)
  return function(sk)
    require("http_conn")(srv, sk)
  end
end

local function main(port)
  package.loaded[modname] = nil

  local p = port or 80
  local srv = {
    routes = {},
    srv = nil
  }
  require("log").info("starting http server on port " .. p)
  srv.srv = net.createServer(net.TCP, 30)
  srv.srv:listen(p, listenFn(srv))
  return srv
end

return main
