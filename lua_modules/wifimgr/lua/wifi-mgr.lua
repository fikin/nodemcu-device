--[[
  Wifi connection manager.

  It maintains STA mode and if not connected for some time starts AP mode in parallel.

  It attempts to reconnect to STA periodically.
]]
local modname = ...

---@class cfg_wifi_mgr
---@field staRetryPeriod integer
---@field apStartDelay integer
---@field sntpSync boolean
---@field mdsnAdv boolean

---@class wifi_event_auth_change
---@field new_auth_mode integer|string
---@field old_auth_mode integer|string

---@class wifi_event_disconnect
---@field reason integer|string

local log = require("log")
local wifi = require("wifi")


---@return cfg_wifi_mgr
local function getSettings()
  return require("device-settings")(modname)
end

---post a task
---@param fn fun()
local function postTask(fn)
  local task = require("node").task
  task.post(task.MEDIUM_PRIORITY, fn)
end

---sets the mode away from sta, used after disconnect to pacify
---some repeating disconnect events fired by firmware
local function setAwayFromSta()
  local mode = wifi.getmode()
  if mode == wifi.STATION or mode == wifi.STATIONAP then
    wifi.setmode(mode == wifi.STATION and wifi.NULLMODE or wifi.SOFTAP)
  end
end

---runs sta connection
local function connectSta()
  log.info("trying to connect to %s", wifi.sta.getconfig(true).ssid)
  wifi.sta.connect()
end

---starts sta mode
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

---start up ap mode
local function setApOn()
  local mode = wifi.getmode()
  if mode == wifi.STATION or mode == wifi.STATIONAP then
    local status = wifi.sta.status()
    if status == wifi.STA_GOTIP then
      if mode == wifi.STATIONAP then
        -- stop AP if connected to STA
        log.info("shutting down ap %s", wifi.ap.getconfig(true).ssid)
        wifi.ap.dhcp.stop()
        wifi.setmode(wifi.STATION)
      end
      return
    end
  end
  -- start AP if not connected to STA
  if mode == wifi.NULLMODE or mode == wifi.STATION then
    log.info("starting up ap %s", wifi.ap.getconfig(true).ssid)
    wifi.setmode(mode == wifi.NULLMODE and wifi.SOFTAP or wifi.STATIONAP)
    if not wifi.ap.dhcp.start() then
      log.debug("starting up AP dhcp server failed")
    end
  end
end

---called after disconnect from sta happened
---tries to reconnect immediately if auth expired
---or sets timers for periodic reconnect check
---and starting ap if long enough did not succeeded to connect to sta
---@param reason number
local function afterDisconnect(reason)
  if reason == wifi.eventmon.reason.AUTH_EXPIRE or
      reason == wifi.eventmon.reason.ASSOC_EXPIRE then
    -- try again directly, this seems related to ESP itself ...
    trySta()
  else
    setAwayFromSta() -- this will disable periodic disconnect calls from firmware
    local settings = getSettings()
    local c = require("call-later")
    c(settings.staRetryPeriod, trySta)
    c(settings.apStartDelay, setApOn)
    if settings.mdsnAdv then require("mdns-adv")("stop") end
  end
end

---called on disconnect from sta endpoint
---tries reconnect or schedules such
---@param T wifi_event_disconnect as provided by wifi.event
local function onStaDisconnect(T)
  local reason = tonumber(T.reason) or 0
  T.reason = require("wifi-reasons")(reason)
  log.info("disconnected from %s", log.json, T)

  ---a wrapper to afterDisconnect
  local fn = function()
    afterDisconnect(reason)
  end
  postTask(fn)
end

---called on sta connected to ssid, logs it
---@param T table as provided by wifi.event
local function onStaConnect(T)
  log.info("connected to %s", log.json, T)
end

---called on wifi sta auth mode change, logs it
---@param T wifi_event_auth_change as provided by wifi.event
local function onStaAuthModeChange(T)
  local d = require("wifi-authmode")
  T.new_auth_mode = d(tonumber(T.new_auth_mode) or 0)
  T.old_auth_mode = d(tonumber(T.old_auth_mode) or 0)
  log.info("authorization mode changed %s", log.json, T)
end

---called on sta dhcp timeout, logs it only
---@param T table as provided by wifi.event
local function onStaDhcpTimeout(T)
  log.info("dhcp timeout")
end

---called on sta-ip address assigned
---shutdowns ap if still connected after 1min
---@param T table as provided by wifi.event
local function onStaGotIp(T)
  log.info("got ip %s", log.json, T)

  local settings = getSettings()
  if settings.sntpSync then
    -- do sntp sync if present, we do not care if missing
    require("sntp-sync")()
  end
  if settings.mdsnAdv then
    require("mdns-adv")("start")
  end

  -- switch off AP if ok
  local fn = function()
    require("call-later")(1000 * 60, setApOn)
  end
  postTask(fn)
end

---called on wifi mode change, logs it
---@param T table as provided by wifi.event
local function onWifiModeChanged(T)
  local d = require("wifi-wifimode")
  T.new_mode = d(tonumber(T.new_mode) or 0)
  T.old_mode = d(tonumber(T.old_mode) or 0)
  log.info("wifi mode changed %s", log.json, T)
end

---called on ap-connected, audits the client
---@param T table as provided by wifi.event
local function onApConnected(T)
  log.audit("accepted connection from %s", log.json, T)
end

---called on ap-disconnect, audits the client
---@param T table as provided by wifi.event
local function onApDisconnected(T)
  log.audit("connection closed from %s", log.json, T)
end

---assign wifi.event callbacks via which the orchestration
---of sta/ap modes is happening
local function assignCbs()
  local onFnc = function(_, eventType, fnc)
    wifi.eventmon.register(eventType, fnc)
  end
  onFnc(modname, wifi.eventmon.STA_DISCONNECTED, onStaDisconnect)
  onFnc(modname, wifi.eventmon.STA_CONNECTED, onStaConnect)
  onFnc(modname, wifi.eventmon.STA_AUTHMODE_CHANGE, onStaAuthModeChange)
  onFnc(modname, wifi.eventmon.STA_DHCP_TIMEOUT, onStaDhcpTimeout)
  onFnc(modname, wifi.eventmon.STA_GOT_IP, onStaGotIp)
  onFnc(modname, wifi.eventmon.WIFI_MODE_CHANGED, onWifiModeChanged)
  onFnc(modname, wifi.eventmon.AP_STACONNECTED, onApConnected)
  onFnc(modname, wifi.eventmon.AP_STADISCONNECTED, onApDisconnected)
end

local function hasSSIDDefined(moduleName)
  local cfg = require("device-settings")(moduleName)
  return cfg
      and cfg.config
      and cfg.config.ssid
      and #cfg.config.ssid > 0
      and cfg.config.ssid:sub(1, 1) ~= "<"
end

---starts wifi management
---it tries to connect to sta if it is defined
---it starts ap if sta is not defined
local function main()
  package.loaded[modname] = nil

  wifi.setmode(wifi.NULLMODE) -- reset state just for any case

  assignCbs()

  if hasSSIDDefined("wifi-sta") then
    trySta() -- try to connect to sta
  elseif hasSSIDDefined("wifi-ap") then
    setApOn() -- start ap right on
  end
end

return main
