--[[
  Applies wifi configuration settings.

Usage: require("wifi-apply-config")(cfg)
where:
  - cfg is configuration object as returned by "wifi_ap_defaults" or "wifi_sta_defaults"

  Note: this module does not assign callbacks, that one has to do via "wifi_event".
]]
local modname = ...

---@class cfg_wifi
---@field maxtxpower integer
---@field phymode integer
---@field country wifi_country

---@class cfg_sta
---@field hostname string
---@field config wifi_sta_config
---@field mac string
---@field staticIp table
---@field sleepType integer

---@class cfg_ap
---@field hostname string
---@field config wifi_ap_config
---@field staticIp table
---@field dhcpConfig table
---@field mac string

local log, wifi = require("log"), require("wifi")
local tblClone = require("table-clone")

---configures wifi common settings
---@param cfg cfg_wifi
local function setWifiCfg(cfg)
  wifi.setmode(wifi.NULLMODE)

  log.debug("setting country %s", log.json, cfg.country)
  if not wifi.setcountry(cfg.country) then
    log.error("failed to set country")
  end

  log.debug("setting max tx power to %d", cfg.maxtxpower)
  wifi.setmaxtxpower(cfg.maxtxpower)

  log.debug("setting protocol to %d", cfg.phymode)
  wifi.setphymode(cfg.phymode)
end

---configures wifi.sta settings
---@param cfg cfg_sta
local function setSTACfg(cfg)
  wifi.setmode(wifi.STATION)

  log.debug("setting hostname %s", cfg.hostname)
  if not wifi.sta.sethostname(cfg.hostname) then
    log.error("failed to set hostname")
  end
  if cfg.mac then
    log.debug("setting station mac address %s", cfg.mac)
    if not wifi.sta.setmac(cfg.mac) then
      log.error("failed to set station mac address")
    end
  end

  if cfg.staticIp then
    log.debug("setting station static ip address %s", log.json, cfg.staticIp)
    if not wifi.sta.setip(cfg.staticIp) then
      log.error("failed to set station static ip address")
    end
  end

  log.debug("setting station sleep type %d", cfg.sleepType)
  if not wifi.sta.sleeptype(cfg.sleepType) then
    log.error("failed to set station sleep type")
  end

  log.debug("setting station config %s", log.json, cfg.config)
  if not wifi.sta.config(tblClone(cfg.config)) then
    log.error("failed to set station config")
  end

  wifi.sta.autoconnect(cfg.config.auto and 1 or 0)
end

---configures wifi.ap settings
---@param cfg cfg_ap
local function setAPCfg(cfg)
  wifi.setmode(wifi.SOFTAP)

  if cfg.mac then
    log.debug("setting access point mac address %s", cfg.mac)
    if not wifi.ap.setmac(cfg.mac) then
      log.error("failed to set access point mac address")
    end
  end

  log.debug("setting access point dhcp config %s", log.json, cfg.dhcpConfig)
  local pool_startip, pool_endip = wifi.ap.dhcp.config(cfg.dhcpConfig)
  log.debug("dhcp pool startip=%s, endip=%s", pool_startip, pool_endip)

  log.debug("setting access point ip address %s", log.json, cfg.staticIp)
  if not wifi.ap.setip(cfg.staticIp) then
    log.error("failed to set access point ip address")
  end

  log.debug("setting access point config %s", log.json, cfg.config)
  if not wifi.ap.config(tblClone(cfg.config)) then
    log.error("failed to set access point config")
  end
end

---configures all wifi settings for sta and ap
local function main()
  package.loaded[modname] = nil

  local ds = require("device-settings")

  setWifiCfg(ds("wifi"))
  setSTACfg(ds("wifi-sta"))
  setAPCfg(ds("wifi-ap"))

  -- reset mode so wifimgr can start anew
  wifi.setmode(wifi.NULLMODE)
end

return main
