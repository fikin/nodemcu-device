--[[
  Wifi connection manager.

  It maintains STA mode and if not connected for some time starts AP mode in parallel.

  It attempts to reconnect to STA periodically.
]]
local modname = ...

local log = require("log")
local wifi = require("wifi")

local devSettings = require("device_settings")(modname)
local connectLaterDelay = devSettings.staRetryPeriod or (1000 * 60)
local checkGotIpDelay = devSettings.apStartDelay or (1000 * 60 * 2)

local function setAwayFromSta()
  local mode = wifi.getmode()
  if mode == wifi.STATION or mode == wifi.STATIONAP then
    wifi.setmode(mode == wifi.STATION and wifi.NULLMODE or wifi.SOFTAP)
  end
end

local function connectSta()
  log.info("trying to connect to %s" % wifi.sta.getconfig(true).ssid)
  wifi.sta.connect()
end

local function trySta()
  local mode = wifi.getmode()
  -- connect to STA if not connected already
  if mode ~= wifi.STATION and mode ~= wifi.STATIONAP then
    wifi.setmode(mode == wifi.NULLMODE and wifi.STATION or wifi.STATIONAP)
    connectSta()
  else
    local status = wifi.sta.status()
    if status ~= wifi.STA_GOTIP and status ~= wifi.STA_CONNECTING then
      connectSta()
    end
  end
end

local function setApOn()
  local mode = wifi.getmode()
  if mode == wifi.STATION or mode == wifi.STATIONAP then
    local status = wifi.sta.status()
    if status == wifi.STA_GOTIP then
      if mode == wifi.STATIONAP then
        -- stop AP if connected to STA
        log.info("shutting down ap %s" % wifi.ap.getconfig(true).ssid)
        wifi.ap.dhcp.stop()
        wifi.setmode(wifi.STATION)
      end
      return
    end
  end
  -- start AP if not connected to STA
  if mode == wifi.NULLMODE or mode == wifi.STATION then
    log.info("starting up ap %s" % wifi.ap.getconfig(true).ssid)
    wifi.setmode(mode == wifi.NULLMODE and wifi.SOFTAP or wifi.STATIONAP)
    if not wifi.ap.dhcp.start() then
      log.debug("starting up AP dhcp server failed")
    end
  end
end

local function afterDisconnect(reason)
  if reason == wifi.eventmon.reason.AUTH_EXPIRE then
    -- try again directly, this seems related to ESP itself ...
    trySta()
  else
    setAwayFromSta() -- this will disable periodic disconnect calls from firmware
    local c = require("call_later")
    c(connectLaterDelay, trySta)
    c(checkGotIpDelay, setApOn)
  end
end

local function onStaDisconnect(T)
  local reason = T.reason
  T.reason = require("wifi_reasons")(T.reason)
  log.info("disconnected from", log.json, T)

  local fn = function()
    afterDisconnect(reason)
  end
  require("node").task.post(fn)
end

local function onStaConnect(T)
  log.info("connected to", log.json, T)
end

local function onStaAuthModeChange(T)
  local d = require("wifi_authmode")
  T.new_auth_mode = d(T.new_auth_mode)
  T.old_auth_mode = d(T.old_auth_mode)
  log.info("authorization mode changed", log.json, T)
end

local function onStaDhcpTimeout(T)
  log.info("dhcp timeout")
end

local function onStaGotIp(T)
  log.info("got ip", log.json, T)

  -- switch off AP if ok
  local fn = function()
    require("call_later")(1000 * 60, setApOn)
  end
  require("node").task.post(fn)
end

local function onWifiModeChanged(T)
  local d = require("wifi_wifimode")
  T.new_mode = d(T.new_mode)
  T.old_mode = d(T.old_mode)
  log.info("wifi mode changed", log.json, T)
end

local function onApConnected(T)
  log.audit("accepted connection from", log.json, T)
end

local function onApDisconnected(T)
  log.audit("connection closed from", log.json, T)
end

local function assignCbs()
  local onFnc = require("wifi_event")
  onFnc(modname, wifi.eventmon.STA_DISCONNECTED, onStaDisconnect)
  onFnc(modname, wifi.eventmon.STA_CONNECTED, onStaConnect)
  onFnc(modname, wifi.eventmon.STA_AUTHMODE_CHANGE, onStaAuthModeChange)
  onFnc(modname, wifi.eventmon.STA_DHCP_TIMEOUT, onStaDhcpTimeout)
  onFnc(modname, wifi.eventmon.STA_GOT_IP, onStaGotIp)
  onFnc(modname, wifi.eventmon.WIFI_MODE_CHANGED, onWifiModeChanged)
  onFnc(modname, wifi.eventmon.AP_STACONNECTED, onApConnected)
  onFnc(modname, wifi.eventmon.AP_STADISCONNECTED, onApDisconnected)
end

local function main()
  package.loaded[modname] = nil

  wifi.setmode(wifi.NULLMODE) -- reset state just for any case

  assignCbs()

  local sta = requrie("device_settings")("sta")
  local ap = requrie("device_settings")("ap")

  if sta and #sta.config.ssid > 0 then
    trySta() -- try to connect to sta
  elseif ap and #ap.config.ssid > 0 then
    setApOn() -- start ap right on
  end
end

return main
