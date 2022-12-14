local modname = ...

---resolve status code to its text
---@param status integer
---@return string
local function main(status)
  package.loaded[modname] = nil

  local wifi = require("wifi")
  local t = {
    [wifi.STA_IDLE] = "STA_IDLE",
    [wifi.STA_CONNECTING] = "STA_CONNECTING",
    [wifi.STA_WRONGPWD] = "STA_WRONGPWD",
    [wifi.STA_APNOTFOUND] = "STA_APNOTFOUND",
    [wifi.STA_FAIL] = "STA_FAIL",
    [wifi.STA_GOTIP] = "STA_GOTIP"
  }
  return t[status] or tostring(status)
end

return main
