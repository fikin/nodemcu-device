local modname = ...

---encode argument to json
---@param v any
---@return string
local function main(v)
  package.loaded[modname] = nil

  if type(v) == "table" then
    local sjson = require("sjson")
    local ok, ret = pcall(sjson.encode, v)
    if not ok then
      ret = sjson.encode(require("table-as-str")(v))
    end
    ---@cast ret string
    return ret
  end
  return tostring(v)
end

return main
