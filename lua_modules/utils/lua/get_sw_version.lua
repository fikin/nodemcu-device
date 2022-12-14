--[[
  Returns version packages with LFS image
]]
local modname = ...

local function main()
  package.loaded[modname] = nil
  return require("read_json_file")("_sw_version.json")
end

return main
