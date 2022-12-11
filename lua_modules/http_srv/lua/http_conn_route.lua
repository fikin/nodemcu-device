--[[
  Routes HTTP request.

  It recognizes fixed routes in the format "<method> <url>".

  It recognizes Lua string patterns in the format "#<string pattern>".
  The mathing happens against the request text in the format of "<method> <url>".

  Query arguments are considered part of the url text (for now).
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

local function main(routes, conn)
  package.loaded[modname] = nil

  local routingKey = conn.req.method .. " " .. conn.req.url
  local route = findRoute(routingKey, routes)
  if route then
    require("log").info(routingKey)
    route(conn)
  else
    error("404: no route found for %s" % routingKey)
  end
end

return main
