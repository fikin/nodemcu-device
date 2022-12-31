--[[
  Returns version packages with LFS image
]]
local modname = ...

---@class sw_version_json
---@field version string

---returns content of _sw_version.json file
---@return sw_version_json
local function main()
  package.loaded[modname] = nil
  return require("read_json_file")("_sw_version.json")
end

return main
