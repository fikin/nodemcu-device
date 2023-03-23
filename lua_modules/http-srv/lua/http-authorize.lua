--[[
  HTTP handler for authentication.
]]
local modname = ...

---data structure for keeping basic authentication data
---@class http_h_auth
---@field usr string
---@field pwd string
---@field realm string

---checks request's authentication and returns false if it does not match
---@param cfg http_h_auth
---@param conn http_conn*
---@return boolean
local function isAuthenticated(cfg, conn)
  local txt = conn.req.headers["Authorization"]
  if txt then
    local _, _, auth = string.find(txt, "Basic (%w+=+)")
    if auth then
      local cred = require("encoder").fromBase64(auth)
      local _, _, usr, pwd = string.find(cred, "(%w+):(.+)")
      return cfg.usr == usr and cfg.pwd == pwd
    end
  end
  return false
end

---checks if the request is authenticated i.e. has WWW-Authenticate Basic
---@param conn http_conn*
---@param creds http_h_auth
---@return boolean
---@return string|nil
local function main(conn, creds)
  -- package.loaded[modname] = nil -- cached, for better tiny performance

  if isAuthenticated(creds, conn) then
    return true, nil
  else
    conn.resp.code = "401"
    conn.resp.headers["WWW-Authenticate"] = string.format('Basic realm="%s", charset="UTF-8"', creds.realm)
    return false, nil
  end
end

return main
