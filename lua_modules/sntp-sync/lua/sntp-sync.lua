--[[
  Performs SNTP sync.

  Depends on : log, sntp

  Usage:
    require("sntp-sync")()

  This module is orchestrating the periodic sync on its own
  as C-module tends to coredumps and reboots device in case of concurrent sync calls.
]]
--
local modname = ...

---@class sntp_sync_cfg
---@field syncIntervalSec integer
---@field serverIps string[]

---@class sntp_sync_state
---@field syncOngoing boolean
---@field tmr tmr_instance

local state = require("rtc-state")("sntp-sync")

---tests if wifi is having IP address in station mode
---@return boolean
local function isConnected()
  local wifi = require("wifi")
  local mode = wifi.getmode()
  if mode == wifi.STATION or mode == wifi.STATIONAP then
    return wifi.sta.status() == wifi.STA_GOTIP
  else
    return false
  end
end

---called each time snmp sync fails
---it logs error if connected to station, otheriwise ignores it
---@param code integer
---@param err string error text
local function errCbFn(code, err)
  state(nil, tonumber(false)) -- not ongoing
  require("log").error("%s: %s", require("sntp-dns-code")(code), err)
end

---called each time successfully synced the time
---@param sec integer
---@param micro integer
---@param srv string
---@param info any
local function okCbFn(sec, micro, srv, info)
  state(nil, tonumber(false)) -- not ongoing
  local log = require("log")
  log.info("%s", log.json, { sec = sec, micro = micro, srv = srv, info = info })
end

---callback called by wifi event
local function wifiCbFn()
  if isConnected() then
    state(nil, tonumber(true)) -- ongoing
    require("sntp").sync(nil, okCbFn, errCbFn, nil)
  else
    require("log").debug("skipping, not connected to internet")
  end
end

---initialize cfg with device settings
local function init()
  local tmr = require("tmr")

  ---@type sntp_sync_cfg
  local cfg = require("device-settings")(modname)

  -- repeating NTP sync
  tmr.create():alarm(cfg.syncIntervalSec * 1000, tmr.ALARM_AUTO, wifiCbFn)

  require("sntp").sync(cfg.serverIps, okCbFn, errCbFn, nil)
end

---register for wifi event when getting ip address, to sync the time
local function main()
  package.loaded[modname] = nil

  local ok, val = state()
  if ok then
    if val == 0 then -- not ongoing
      wifiCbFn()
    end
  else
    init()
  end
end

return main
