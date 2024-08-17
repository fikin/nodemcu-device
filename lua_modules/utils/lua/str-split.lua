local modname = ...

---splits text by delimiter
---@param text string
---@param delimiter string
---@return string[]
local function main(text, delimiter)
  package.loaded[modname] = nil

  local result            = {}
  local from              = 1
  while true do
    local delim_from, delim_to = string.find(text, delimiter, from)
    if not delim_from then break end
    table.insert(result, string.sub(text, from, delim_from - 1))
    from = delim_to + 1
  end
  table.insert(result, string.sub(text, from))
  return result
end



return main
