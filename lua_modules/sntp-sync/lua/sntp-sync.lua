--[[
  Performs SNTP sync.
  
  Depends on : log, sntp
  
  Usage: 
    require("sntp-sync")()
]] --
local modname = ...

local syncOngoing = false

---called each time snmp sync fails
---it logs error if connected to station, otheriwise ignores it
---@param code integer
---@param err string error text
local function errCbFn(code, err)
  syncOngoing = false
  local wifi = require("wifi")
  local mode = wifi.getmode()
  if mode == wifi.STATION or mode == wifi.STATIONAP then
    if wifi.sta.status() == wifi.STA_GOTIP then
      -- report error only if wifi is connected
      -- all other cases likely error is due to missing connectivity
      require("log").error("%s: %s",require("sntp-dns-code")(code), err)
    end
  end
end

---called each time successfully synced the time
---@param sec integer
---@param micro integer
---@param srv string
---@param info any
local function okCbFn(sec, micro, srv, info)
  syncOngoing = false
  local log = require("log")
  log.info("%s", log.json, { sec = sec, micro = micro, srv = srv, info = info })
end

---callback called by wifi event
local function wifiCbFn()
  syncOngoing = true
  local srvLst = nil -- TODO use device_settings to get configurable list of servers
  require("sntp").sync(srvLst, okCbFn, errCbFn, 1)
end

---register for wifi event when getting ip address, to sync the time
local function main()
  if not syncOngoing then
    wifiCbFn()
  end
end

return main
