local modname = ...

---reads given file (in json format) and returns its content as table
---@param fName string file to read
---@return table
local function main(fName)
  package.loaded[modname] = nil
  if require("file").exists(fName) then
    local txt = require("file").getcontents(fName)
    return require("sjson").decode(txt)
  else
    error(string.format("missing file %s", fName))
  end
end

return main
