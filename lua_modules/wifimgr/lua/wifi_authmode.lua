local modname = ...

local t = {
  [wifi.OPEN] = "OPEN",
  [wifi.WPA_PSK] = "WPA_PSK",
  [wifi.WPA2_PSK] = "WPA2_PSK",
  [wifi.WPA_WPA2_PSK] = "WPA_WPA2_PSK"
}

local function main(mode)
  package.loaded[modname] = nil
  return t[mode] or tostring(mode)
end

return main