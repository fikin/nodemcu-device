--[[
    This file is template, modify it with one-time configuration steps
    to be executed after reboot.

    Following settings are relevant for initial flashing of the device,
    consequent sw upgrades should have its own changes if needed be.
   ]]

local fs = require("factory-settings")

--fs("wifi-sta"):set("config.ssid","<SSID>"):set("config.pwd","<PWD>"):set("hostname","<HOSTNAME>"):done()

-- minimal set of modules on
-- fs("init-seq"):set("bootsequence",{ "bootstrap", "user-settings", "log-start", "wifi-apply-config", "wifi-mgr", "http-srv", "telnet" }):done()

-- likely same credentials for admin services
-- fs("telnet"):set("usr", "<ADMIN>"):set("pwd", "<APWD>"):done()
-- fs("web-portal"):set("usr", "<ADMIN>"):set("pwd", "<APWD>"):done()
-- fs("web-ota"):set("usr", "<ADMIN>"):set("pwd", "<APWD>"):done()

-- minimal HomeAssistant modules and credentials
--fs("web-ha"):set("entities", { "system-hass" }):set("credentials.usr", "<HAUSER>"):set("credentials.pwd", "<HAPWD>"):done()
