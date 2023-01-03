local modname = ...

---resolve mode into its text form
---@param mode integer
---@return string
local function main(mode)
  package.loaded[modname] = nil

  local wifi = require("wifi")
  local t = {
    [wifi.OPEN] = "OPEN",
    [wifi.WPA_PSK] = "WPA_PSK",
    [wifi.WPA2_PSK] = "WPA2_PSK",
    [wifi.WPA_WPA2_PSK] = "WPA_WPA2_PSK"
  }

  return t[mode] or tostring(mode)
end

return main
