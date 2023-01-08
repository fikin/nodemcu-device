--[[
  Reads request payload as json object
]]
local modname = ...

---reads readFn as being json and returns resulting table
---@param readFn function
---@return table
local function readAsJson(readFn)
  local decoder = require("sjson").decoder()
  while true do
    local buf = readFn()
    if buf then
      decoder:write(buf)
    else
      break
    end
  end
  return decoder:result()
end

---expects application/json and returns the read object
---@param conn http_conn*
---@return table
local function main(conn)
  package.loaded[modname] = nil

  local ct = conn.req.headers["Content-Type"]
  if ct == "application/json" then
    conn.resp.code = "200"
    return readAsJson(conn.req.body)
  else
    error(string.format("expected Content-Type: application/json but got %s", ct))
  end
end

return main
