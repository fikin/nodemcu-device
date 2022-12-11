--[[
  HTTP handler :
    - saving file in <file>.tmp first
    - then moving <file> to <file>.bak (original)
    - then moving <file>.tmp to <file>
]]
local modname = ...

local function main(nextHandler, noBackup)
  package.loaded[modname] = nil

  return function(conn)
    local fName = string.sub(conn.req.url, 2)
    local fTmp = fName .. ".tmp"
    local fBak = fName .. ".bak"

    local file = require("file")

    file.remove(fTmp)

    conn.req.url = "/" .. fTmp
    nextHandler(conn)

    file.remove(fBak)
    if not noBackup and file.exists(fName) and not file.rename(fName, fBak) then
      error("500: failed to take file backup of " .. fName)
    end

    file.remove(fName)
    if not file.rename(fTmp, fName) then
      error("500: failed to rename file %s to %s" % {fTmp, fName})
    end

    if noBackup then
      file.remove(fBak)
    end
  end
end

return main
