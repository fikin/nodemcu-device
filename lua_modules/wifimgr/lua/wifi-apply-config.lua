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

---configures wifi common settings
---@param cfg cfg_wifi
local function setWifiCfg(cfg)
  log.debug(modname, "setting country", log.json, cfg.country)
  if not wifi.setcountry(cfg.country) then
    log.error(modname, "failed to set country")
  end

  log.debug(modname, "setting max tx power to", cfg.maxtxpower)
  wifi.setmaxtxpower(cfg.maxtxpower)

  log.debug(modname, "setting protocol to", cfg.phymode)
  wifi.setphymode(cfg.phymode)
end

---configures wifi.sta settings
---@param cfg cfg_sta
local function setSTACfg(cfg)
  log.debug(modname, "setting hostname", cfg.hostname)

  if not wifi.sta.sethostname(cfg.hostname) then
    log.error(modname, "failed to set hostname")
  end
  if cfg.mac then
    log.debug(modname, "setting station mac address", cfg.mac)
    if not wifi.sta.setmac(cfg.mac) then
      log.error(modname, "failed to set station mac address")
    end
  end

  if cfg.staticIp then
    log.debug(modname, "setting station static ip address", log.json, cfg.staticIp)
    if not wifi.sta.setip(cfg.staticIp) then
      log.error(modname, "failed to set station static ip address")
    end
  end

  log.debug(modname, "setting station sleep type", cfg.sleepType)
  if not wifi.sta.sleeptype(cfg.sleepType) then
    log.error(modname, "failed to set station sleep type")
  end

  log.debug(modname, "setting station config", log.json, cfg.config)
  if not wifi.sta.config(cfg.config) then
    log.error(modname, "failed to set station config")
  end

  wifi.sta.autoconnect(cfg.config.auto and 1 or 0)
end

---configures wifi.ap settings
---@param cfg cfg_ap
local function setAPCfg(cfg)
  if cfg.mac then
    log.debug(modname, "setting access point mac address", cfg.mac)
    if not wifi.ap.setmac(cfg.mac) then
      log.error(modname, "failed to set access point mac address")
    end
  end

  log.debug(modname, "setting access point dhcp config", log.json, cfg.dhcpConfig)
  local pool_startip, pool_endip = wifi.ap.dhcp.config(cfg.dhcpConfig)
  log.debug(modname, string.format("dhcp pool startip=%s, endip=%s", pool_startip, pool_endip))

  log.debug(modname, "setting access point ip address", log.json, cfg.staticIp)
  if not wifi.ap.setip(cfg.staticIp) then
    log.error(modname, "failed to set access point ip address")
  end

  log.debug(modname, "setting access point config", log.json, cfg.config)
  if not wifi.ap.config(cfg.config) then
    log.error(modname, "failed to set access point config")
  end
end

---configures all wifi settings for sta and ap
local function main()
  package.loaded[modname] = nil

  local cfg = require("device-settings")()

  wifi.setmode(wifi.NULLMODE)
  if cfg.wifi then
    setWifiCfg(cfg.wifi)
  end
  if cfg.sta then
    setSTACfg(cfg.sta)
  end
  if cfg.ap then
    setAPCfg(cfg.ap)
  end
end

return main
