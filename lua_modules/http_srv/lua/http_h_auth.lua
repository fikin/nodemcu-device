--[[
  HTTP handler for authentication.
]]
local modname = ...

local function isAuthenticated(cfg, conn)
  local _, _, auth = string.find(conn.req.headers, "Authorization: Basic (%w+=+)\r\n")
  if auth then
    local cred = require("encoder").fromBase64(auth)
    local _, _, usr, pwd = string.find(cred, "(%w+):(.+)")
    return cfg.usr == usr and cfg.pwd == pwd
  else
    return false
  end
end

local function main(cfg, nextHandler)
  package.loaded[modname] = nil

  return function(conn)
    if isAuthenticated(cfg, conn) then
      nextHandler(conn)
    else
      conn.resp.code = "401"
      conn.resp.headers["WWW-Authenticate"] = 'Basic realm="%s", charset="UTF-8"' % cfg.realm
    end
  end
end

return main
