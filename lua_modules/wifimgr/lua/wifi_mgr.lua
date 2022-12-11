--[[
  Wifi connections manager.
]]
local modname = ...

local log = require("log")
local wifi = require("wifi")

local state = require("state")(modname)

local devSettings = require("device_settings")
local modSettings = devSettings.wifiMgr
local connectLaterDelay = modSettings.staRetryPeriod or (1000 * 60)
local checkGotIpDelay = modSettings.apStartDelay or (1000 * 60 * 2)

local function decodeDisconnectReason(reason)
  local t = {
    [wifi.eventmon.reason.UNSPECIFIED] = "UNSPECIFIED",
    [wifi.eventmon.reason.AUTH_EXPIRE] = "AUTH_EXPIRE",
    [wifi.eventmon.reason.AUTH_LEAVE] = "AUTH_LEAVE",
    [wifi.eventmon.reason.ASSOC_EXPIRE] = "ASSOC_EXPIRE",
    [wifi.eventmon.reason.ASSOC_TOOMANY] = "ASSOC_TOOMANY",
    [wifi.eventmon.reason.NOT_AUTHED] = "NOT_AUTHED",
    [wifi.eventmon.reason.NOT_ASSOCED] = "NOT_ASSOCED",
    [wifi.eventmon.reason.ASSOC_LEAVE] = "ASSOC_LEAVE",
    [wifi.eventmon.reason.ASSOC_NOT_AUTHED] = "ASSOC_NOT_AUTHED",
    [wifi.eventmon.reason.DISASSOC_PWRCAP_BAD] = "DISASSOC_PWRCAP_BAD",
    [wifi.eventmon.reason.DISASSOC_SUPCHAN_BAD] = "DISASSOC_SUPCHAN_BAD",
    [wifi.eventmon.reason.IE_INVALID] = "IE_INVALID",
    [wifi.eventmon.reason.MIC_FAILURE] = "MIC_FAILURE",
    [wifi.eventmon.reason["4WAY_HANDSHAKE_TIMEOUT"]] = "4WAY_HANDSHAKE_TIMEOUT",
    [wifi.eventmon.reason.GROUP_KEY_UPDATE_TIMEOUT] = "GROUP_KEY_UPDATE_TIMEOUT",
    [wifi.eventmon.reason.IE_IN_4WAY_DIFFERS] = "IE_IN_4WAY_DIFFERS",
    [wifi.eventmon.reason.GROUP_CIPHER_INVALID] = "GROUP_CIPHER_INVALID",
    [wifi.eventmon.reason.PAIRWISE_CIPHER_INVALID] = "PAIRWISE_CIPHER_INVALID",
    [wifi.eventmon.reason.AKMP_INVALID] = "AKMP_INVALID",
    [wifi.eventmon.reason.UNSUPP_RSN_IE_VERSION] = "UNSUPP_RSN_IE_VERSION",
    [wifi.eventmon.reason.INVALID_RSN_IE_CAP] = "INVALID_RSN_IE_CAP",
    [wifi.eventmon.reason["802_1X_AUTH_FAILED"]] = "802_1X_AUTH_FAILED",
    [wifi.eventmon.reason.CIPHER_SUITE_REJECTED] = "CIPHER_SUITE_REJECTED",
    [wifi.eventmon.reason.BEACON_TIMEOUT] = "BEACON_TIMEOUT",
    [wifi.eventmon.reason.NO_AP_FOUND] = "NO_AP_FOUND",
    [wifi.eventmon.reason.AUTH_FAIL] = "AUTH_FAIL",
    [wifi.eventmon.reason.ASSOC_FAIL] = "ASSOC_FAIL",
    [wifi.eventmon.reason.HANDSHAKE_TIMEOUT] = "HANDSHAKE_TIMEOUT"
  }
  return t[reason] or tostring(reason)
end

local function decodeAuthMode(mode)
  local t = {
    [wifi.OPEN] = "OPEN",
    [wifi.WPA_PSK] = "WPA_PSK",
    [wifi.WPA2_PSK] = "WPA2_PSK",
    [wifi.WPA_WPA2_PSK] = "WPA_WPA2_PSK"
  }
  return t[mode] or tostring(mode)
end

local function decodeWifiMode(mode)
  local t = {
    [wifi.NULLMODE] = "NULLMODE",
    [wifi.SOFTAP] = "SOFTAP",
    [wifi.STATION] = "STATION",
    [wifi.STATIONAP] = "STATIONAP"
  }
  return t[mode] or tostring(mode)
end

local function decodeStaStatus(status)
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

local function callLater(delay, fnc)
  local tmr = require("tmr")
  local t = tmr:create()
  t:register(
    delay,
    tmr.ALARM_SINGLE,
    function(T)
      fnc()
    end
  )
  if not t:start() then
    log.error("failed starting a timer")
  end
end

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

local function assignCbs()
  local onFnc = require("wifi_event")
  onFnc(
    modname,
    wifi.eventmon.STA_DISCONNECTED,
    function(T)
      local reason = T.reason
      T.reason = decodeDisconnectReason(T.reason)
      log.info("disconnected from", log.json, T)

      require("node").task.post(
        function()
          if reason == wifi.eventmon.reason.AUTH_EXPIRE then
            -- try again directly, this seems related to ESP itself ...
            trySta()
          else
            setAwayFromSta() -- this will disable periodic disconnect calls from firmware
            callLater(connectLaterDelay, trySta)
            callLater(checkGotIpDelay, setApOn)
          end
        end
      )
    end
  )
  onFnc(
    modname,
    wifi.eventmon.STA_CONNECTED,
    function(T)
      log.info("connected to", log.json, T)
    end
  )
  onFnc(
    modname,
    wifi.eventmon.STA_AUTHMODE_CHANGE,
    function(T)
      T.new_auth_mode = decodeAuthMode(T.new_auth_mode)
      T.old_auth_mode = decodeAuthMode(T.old_auth_mode)
      log.info("authorization mode changed", log.json, T)
    end
  )
  onFnc(
    modname,
    wifi.eventmon.STA_DHCP_TIMEOUT,
    function(T)
      log.info("dhcp timeout")
    end
  )
  onFnc(
    modname,
    wifi.eventmon.STA_GOT_IP,
    function(T)
      log.info("got ip", log.json, T)

      -- switch off AP if ok
      require("node").task.post(
        function()
          callLater(1000 * 60, setApOn)
        end
      )
    end
  )
  onFnc(
    modname,
    wifi.eventmon.WIFI_MODE_CHANGED,
    function(T)
      T.new_mode = decodeWifiMode(T.new_mode)
      T.old_mode = decodeWifiMode(T.old_mode)
      log.info("wifi mode changed", log.json, T)
    end
  )
  onFnc(
    modname,
    wifi.eventmon.AP_STACONNECTED,
    function(T)
      log.audit("accepted connection from", log.json, T)
    end
  )
  onFnc(
    modname,
    wifi.eventmon.AP_STADISCONNECTED,
    function(T)
      log.audit("connection closed from", log.json, T)
    end
  )
end

local function main()
  package.loaded[modname] = nil

  wifi.setmode(wifi.NULLMODE) -- reset state for any case

  assignCbs()

  if devSettings.sta and #devSettings.sta.config.ssid > 0 then
    trySta() -- try to connect to sta
  elseif devSettings.ap and #devSettings.ap.config.ssid > 0 then
    setApOn() -- start ap right on
  end
end

return main
