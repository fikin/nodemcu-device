--[[
  Clones (deep) one table into another
]]
local modname = ...

---@param tgt table target
---@param src table source
local function cloneTbl(tgt, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      tgt[k] = tgt[k] or {}
      cloneTbl(tgt[k], v)
    else
      tgt[k] = v
    end
  end
end

---deep clone content of tbl as new table
---@param tbl table source to clone
---@return table new cloned table
local function main(tbl)
  package.loaded[modname] = nil
  local o = {}
  cloneTbl(o, tbl)
  return o
end

return main
