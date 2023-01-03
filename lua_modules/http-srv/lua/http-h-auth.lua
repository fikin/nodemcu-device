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
  local _, _, auth = string.find(conn.req.headers, "Authorization: Basic (%w+=+)\r\n")
  if auth then
    local cred = require("encoder").fromBase64(auth)
    local _, _, usr, pwd = string.find(cred, "(%w+):(.+)")
    return cfg.usr == usr and cfg.pwd == pwd
  else
    return false
  end
end

---checks if the request is authenticated i.e. has WWW-Authenticate Basic
---@param cfg http_h_auth
---@param nextHandler conn_handler_fn
---@return conn_handler_fn
local function main(cfg, nextHandler)
  package.loaded[modname] = nil

  return function(conn)
    if isAuthenticated(cfg, conn) then
      nextHandler(conn)
    else
      conn.resp.code = "401"
      conn.resp.headers["WWW-Authenticate"] = string.format('Basic realm="%s", charset="UTF-8"', cfg.realm)
    end
  end
end

return main
