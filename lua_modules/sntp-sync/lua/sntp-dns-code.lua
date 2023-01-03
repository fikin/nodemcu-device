local modname = ...

---@type table<integer,string>
local codes = {
  [1] = "DNS lookup failed",
  [2] = "Memory allocation failure",
  [3] = "UDP send failed",
  [4] = "Timeout, no NTP response received"
}

---looks up text for error code
---@param code integer
---@return string
local function main(code)
  package.loaded[modname] = nil
  return codes[code] or tostring(code)
end

return main
