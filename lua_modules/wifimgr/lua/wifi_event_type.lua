local modname = ...

local names = {
  [wifi.eventmon.STA_CONNECTED] = "STA_CONNECTED",
  [wifi.eventmon.STA_DISCONNECTED] = "STA_DISCONNECTED",
  [wifi.eventmon.STA_AUTHMODE_CHANGE] = "STA_AUTHMODE_CHANGE",
  [wifi.eventmon.STA_GOT_IP] = "STA_GOT_IP",
  [wifi.eventmon.STA_DHCP_TIMEOUT] = "STA_DHCP_TIMEOUT",
  [wifi.eventmon.AP_STACONNECTED] = "AP_STACONNECTED",
  [wifi.eventmon.AP_STADISCONNECTED] = "AP_STADISCONNECTED",
  [wifi.eventmon.AP_PROBEREQRECVED] = "AP_PROBEREQRECVED",
  [wifi.eventmon.WIFI_MODE_CHANGED] = "WIFI_MODE_CHANGED"
}

local function main(eventType)
  package.loaded[modname] = nil
  return names[eventType] or tostring(eventType)
end

return main
