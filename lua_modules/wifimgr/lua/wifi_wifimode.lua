local modname = ...

---resolves wifi mode to its text
---@param mode integer
---@return string
local function main(mode)
  package.loaded[modname] = nil

  local wifi = require("wifi")
  local t = {
    [wifi.NULLMODE] = "NULLMODE",
    [wifi.SOFTAP] = "SOFTAP",
    [wifi.STATION] = "STATION",
    [wifi.STATIONAP] = "STATIONAP"
  }
  return t[mode] or tostring(mode)
end

return main
