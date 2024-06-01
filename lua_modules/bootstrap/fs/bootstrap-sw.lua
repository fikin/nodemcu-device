--[[
    This file is template, modify it with one-time configuration steps
    to be executed after reboot.

    Following settings are relevant for initial flashing of the device,
    consequent sw upgrades should have its own changes if needed be.
   ]]

local fs = require("factory-settings")

-- TODO : typically one wants to update these ones as part
-- of device inital boostrap.
-- Or use web-portal to update it later on too.
-- By default hostname is based on chipID
local hostname = "nodemcu" .. require("node").chipid()
local staSsid = hostname
local staPwd = "1234567890"
local apSsid = hostname .. "_ap"
local apPwd = "1234567890"

local mac = require("wifi").ap.getmac()
fs("wifi-sta"):set("config.ssid", staSsid):set("config.pwd", staPwd):set("hostname", hostname):set("mac", mac):done()
fs("wifi-ap"):set("config.ssid", apSsid):set("config.pwd", apPwd):set("mac", mac):done()

-- likely same credentials for admin services
-- TODO likely update these too
local adminUsr = "admin"
local adminPwd = "admin"
fs("telnet"):set("usr", adminUsr):set("pwd", adminPwd):done()
fs("web-portal"):set("usr", adminUsr):set("pwd", adminPwd):done()
fs("web-ota"):set("usr", adminUsr):set("pwd", adminPwd):done()

-- minimal HomeAssistant modules and credentials
-- fs("web-ha"):set("entities", { "system-hass" }):set("credentials.usr", "<HAUSER>"):set("credentials.pwd", "<HAPWD>"):done()

-- minimal set of modules on.
-- restart at the end since the boot sequence is modified.
-- fs("init-seq"):set("modules",{ "bootstrap", "user-settings", "log-start", "wifi-apply-config", "wifi-mgr", "http-srv", "telnet" }):done()
-- node.restart()
