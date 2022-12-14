local modname = ...

local t = {
  [wifi.NULLMODE] = "NULLMODE",
  [wifi.SOFTAP] = "SOFTAP",
  [wifi.STATION] = "STATION",
  [wifi.STATIONAP] = "STATIONAP"
}

local function main(mode)
  package.loaded[modname] = nil
  return t[mode] or tostring(mode)
end

return main
