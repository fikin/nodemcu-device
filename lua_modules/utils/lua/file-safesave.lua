--[[
Save a file safely, by writing to a temporary file,
taking a backup of the original file
and then renaming it to the target file.
]]

local modname = ...

local file = require("file")

---cleans up temp files during saving
---@param fTmp string
---@param fBak string
local function cleanUpFiles(fTmp, fBak)
  if file.exists(fTmp) then file.remove(fTmp); end
  if file.exists(fBak) then file.remove(fBak); end
end

---renames a file
---@param from string
---@param to string
---@return boolean
local function renameFile(from, to)
  if file.exists(from) then return file.rename(from, to); end
  return true
end

---saves text into file using intermediate fName.bak file
---@param txt string
---@param fName string
local function safeSaveJsonFile(txt, fName)
  local l = require("log")
  l.info("updating %s : %s", fName, txt)
  -- saving is using .tmp and .bak
  local fTmp, fBak = fName .. ".tmp", fName .. ".bak"
  cleanUpFiles(fTmp, fBak)
  if not file.putcontents(fTmp, txt) then
    cleanUpFiles(fTmp, fBak)
    error(string.format("failed saving %s", fTmp))
  end
  file.remove(fBak)
  if not renameFile(fName, fBak) then
    cleanUpFiles(fTmp, fBak)
    error(string.format("failed renaming %s to %s", fName, fBak))
  end
  if not file.rename(fTmp, fName) then
    if not renameFile(fBak, fName) then
      l.error("failed renaming %s to %s", fBak, fName)
    end
    cleanUpFiles(fTmp, fBak)
    error(string.format("failed renaming %s to %s", fTmp, fName))
  end
  cleanUpFiles(fTmp, fBak)
end

---saves file using temporary file and backup of orginal file
---@param filename string
---@param content string
local function main(filename, content)
  package.loaded[modname] = nil -- gc

  safeSaveJsonFile(content, filename)
end

return main
