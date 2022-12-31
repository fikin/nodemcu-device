--[[
  Set http server routes to handle.

  Example:
    require("http_routes").setPath("GET", "/", function(conn) conn.resp.code = 200 end)
    require("http_routes").setMatchPath("GET", "/.+", function(conn) conn.resp.code = 200 end)
]]
local modname = ...

---finds a router function matching given path
---@param path string
---@param routes conn_routes
---@return conn_handler_fn|nil
local function findRoute(path, routes)
  local v = routes[path]
  if v then
    return v
  end
  for k, v in pairs(routes) do
    if string.sub(k, 1, 1) == "#" then
      if string.find(path, string.sub(k, 2)) then
        return v
      end
    end
  end
  return nil
end

---managest http routes for the server
---@class http_routes
local M = {}

---the actual routes
---@type conn_routes
local routes = require("state")(modname)

---assign handler function for given method and path
---@param method string
---@param path string
---@param fnc conn_handler_fn
M.setPath = function(method, path, fnc)
  package.loaded[modname] = nil
  local key = method .. " " .. path
  routes[key] = fnc
end

---assign handler function for all requests whose path matches the pattern
---@param method string
---@param pathPattern string
---@param fnc conn_handler_fn
M.setMatchPath = function(method, pathPattern, fnc)
  package.loaded[modname] = nil
  local key = "#" .. method .. " " .. pathPattern
  routes[key] = fnc
end

---returns the handler function matching given method and path
---returns nil if no route was matched
---query arguments are considered part of the url text (for now).
---@param method string
---@param path string
---@return conn_handler_fn
M.findRoute = function(method, path)
  package.loaded[modname] = nil
  local routingKey = method .. " " .. path
  local fn = findRoute(routingKey, routes)
  if fn then
    return fn
  end
  error("404: no router defind handling %s" % path)
end

return M
