--[[
  Reads request payload as json object
]]
local modname = ...

local function readAsJson(readFn)
  local decoder = sjson.decoder()
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

local function main(conn)
  package.loaded[modname] = nil

  local ct = conn.req.headers["Content-Type"]
  if ct == "application/json" then
    conn.resp.code = "200"
    return readAsJson(conn.req.body)
  else
    error("expected Content-Type: application/json but got %s" % ct)
  end
end

return main
