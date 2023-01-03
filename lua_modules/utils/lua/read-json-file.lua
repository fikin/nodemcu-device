local modname = ...

---reads given file (in json format) and returns its content as table
---@param fName string file to read
---@return table
local function main(fName)
  package.loaded[modname] = nil
  if require("file").exists(fName) then
    local txt = require("file").getcontents(fName)
    if txt then
      return require("str-to-json")(txt)
    end
  end
  error(string.format("missing file %s", fName))
end

return main
