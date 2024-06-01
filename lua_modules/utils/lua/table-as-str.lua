local modname = ...

---creates new table with keys and values explicitly rendered as strings
---@param t table
---@return {string:string}
local function main(t)
  package.loaded[modname] = nil

  local ret = {}
  for k, v in pairs(t) do
    ret[tostring(k)] = tostring(v)
  end
  return ret
end

return main
