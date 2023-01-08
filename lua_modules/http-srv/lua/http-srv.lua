--[[
  HTTP server.

  local s = require("http-srv")(80)
  ...
  Define module name in fs-http-srv.json/webModules.
  Implement <web-module>.lua accepting http_conn*. See web-portal for examples.
]]
local modname = ...

---device configurations for http server
---@class http_srv_cfg
---@field port integer
---@field timeoutSec integer
---@field webModules string[]

---@type http_srv_cfg
local cfg = require("device-settings")(modname)
local webModules = cfg.webModules

---listener function
---@param sk socket
local function listenFn(sk)
  require("http-conn")(sk, webModules)
end

---creates tcp server and binds the listener function to it
local function main()
  package.loaded[modname] = nil

  require("log").info("starting http server on port %d", cfg.port)
  local net = require("net")
  local srv = net.createServer(cfg.timeoutSec)
  srv:listen(cfg.port, listenFn)
end

return main
