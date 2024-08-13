--[[
Saves table as json.

It saves it only if it differs from the existing file.
]]

local modname = ...

local file = require("file")
local sjson = require("sjson")

---converts text to json
---this is called to confirm json encoding before happened
---without any errors. there is some strange bug when saving
---settings occasionally the payload (file content text) is
---rather broken i.e. {d@@@@...} ...
---@param txt string
---@return boolean
local function isJson(txt)
  require("sjson").decode(txt)
  return true
end

---checks if changes are different from saved ones
---@param fName string
---@param txt string
---@return boolean
local function shouldSaveChanges(fName, txt)
  if file.exists(fName) then
    local txt2 = file.getcontents(fName)
    return txt ~= txt2
  end
  return true
end

---saves table as json file
---@param basename string file name, no extension
---@param tbl table to save
---@param ignoreEmptyTable boolean empty tables are not saved
local function main(basename, tbl, ignoreEmptyTable)
  package.loaded[modname] = nil -- gc

  local fName = basename .. ".json"

  local txt = assert(sjson.encode(tbl))
  assert(isJson(txt))
  if ignoreEmptyTable and txt == "[]" then
    -- empty device settings, no need to save them
    file.remove(fName)
  elseif shouldSaveChanges(fName, txt) then
    -- save only if there are changes
    require("file-safesave")(fName, txt)
  end
end

return main
