local modname = ...

local function main(fName)
  package.loaded[modname] = nil
  if require("file").exists(fN) then
    return require("sjson").decode(require("file").getcontents(fName))
  else
    error("missing file %s" % fName)
  end
end

return main
