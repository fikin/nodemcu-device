local modname = ...

---print keys nad their values of the given table
---@param t table
local function main(t)
  package.loaded[modname] = nil

  if type(t) == "table" then
    for k, v in pairs(t) do
      print(k, v)
    end
  else
    print(t)
  end
end

return main
