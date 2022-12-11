--[[
  HTTP hander saving a file.

  It recognizes url in the form "/<file>".
]]
local modname = ...

local function saveContent(readFn, fd)
  while true do
    local buf = readFn()
    if buf then
      if not fd:write(buf) then
        fd:close()
        error("500: failed writing to file")
      end
    else
      break
    end
  end
end

local function main(conn)
  package.loaded[modname] = nil

  local file = require("file")

  local fName = string.sub(conn.req.url, 2)

  local fd = file.open(fName, "w")
  if fd then
    table.insert(
      conn.onGcFn,
      function()
        fd:close() -- just in case someone closes connection before writing is over
      end
    )
    saveContent(conn.req.body, fd)
    fd:close()
    collectgarbage()
    conn.resp.code = "200"
  else
    error("500: cannot open file for writting: " .. fName)
  end
end

return main
