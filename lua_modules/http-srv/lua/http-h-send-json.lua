--[[
  A reusable logic to respond HTTP request with json payload.

  Accepts http conn (http_conn) object and Lua object.
  It serializes the object as json payload.
]]
local modname = ...

---sends 200 status and given body as json mime type
---@param conn http_conn*
---@param data table as response body
local function main(conn, data)
  package.loaded[modname] = nil -- gc

  local txt = require("sjson").encode(data)
  conn.resp.code = "200"
  conn.resp.headers["Content-Type"] = "application/json"
  conn.resp.headers["Content-Length"] = #txt
  conn.resp.body = txt
end

return main
