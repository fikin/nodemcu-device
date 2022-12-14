--[[
  Performs SNTP sync.
  
  Depends on : log, sntp
  
  Usage: 
    require("sntp-sync")()
]] --

local modname = ...

local function errCbFn(code, err)
  local wifi = require("wifi")
  local mode = wifi.getmode()
  if mode == wifi.STATION or mode == wifi.STATIONAP then
    if wifi.sta.status() == wifi.STA_GOTIP then
      -- report error only if wifi is connected
      -- all other cases likely error is due to missing connectivity
      require("log").error(require("sntp_dns_code")(code), err)
    end
  end
end

local function okCbFn(sec, micro, srv, info)
  local log = require("log")
  log.info(log.json, {sec = sec, micro = micro, srv = srv, info = info})
end

local function wifiCbFn()
  local srvLst = nil -- TODO use device_settings to get configurable list of servers
  require("sntp").sync(nil, okCbFn, errCbFn, 1)
end

local function main()
  package.loaded[modname] = nil

  local wifievent, wifi = require("wifi_event"), require("wifi")

  -- auto-keep time up to date when connected to network
  wifievent("sntp_sync", wifi.eventmon.STA_GOT_IP, wifiCbFn)
end

return main
