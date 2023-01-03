--[[
  HTTP server.

  local s = require("http-srv")(80)

  require("http-routes").setPath("GET", "/", function(conn) require("http-return-file")(conn, "index.html") end)
  ...
]]
local modname = ...

---device configurations for http server
---@class http_srv_cfg
---@field port integer
---@field timeoutSec integer

---listener function
---@param sk socket
local function listenFn(sk)
  require("http-conn")(sk)
end

---creates tcp server and binds the listener function to it
local function main()
  package.loaded[modname] = nil

  ---@type http_srv_cfg
  local cfg = require("device-settings")(modname)
  require("log").info("starting http server on port " .. cfg.port)
  local net = require("net")
  local srv = net.createServer(cfg.timeoutSec)
  srv:listen(cfg.port, listenFn)
end

return main
