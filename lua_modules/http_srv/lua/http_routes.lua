--[[
  Set http server routes to handle.

  Example:
    require("http_routes").setPath("GET", "/", function(conn) conn.resp.code = 200 end)
    require("http_routes").setMatchPath("GET", "/.+", function(conn) conn.resp.code = 200 end)
]]
local modname = ...

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

local M = {}

local routes = require("state", modname)

-- assign handler function for given method and path
M.setPath = function(method, path, fnc)
  package.loaded[modname] = nil
  local key = method .. " " .. path
  routes[key] = fnc
end

-- assign handler function for all requests whose path matches the pattern
M.setMatchPath = function(method, pathPattern, fnc)
  package.loaded[modname] = nil
  local key = "#" .. method .. " " .. pathPattern
  routes[key] = fnc
end

-- returns the handler function matching given method and path
-- returns nil if no route was matched
-- query arguments are considered part of the url text (for now).
M.findRoute = function(method, path)
  package.loaded[modname] = nil
  local routingKey = method .. " " .. path
  return findRoute(routingKey, routes)
end

return M
