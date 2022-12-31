--[[
  Main entrypoint when booting up the device
]]

---device init sequence
---it initializes LFS and other modules and runs boot sequence
local function main()
  require("_lfs_init")() -- mandatory first, prepares NodeMCU and LFS

  package.loaded["init"] = nil -- this module gc

  -- device startup sequence
  local b = require("bootprotect")

  b.require("setup device settings", "device_settings_start")
  b.require("configure logger with stored device settings", "log_start")
  b.require("keep time up to date when connected to network", "sntp_sync_start")
  b.require("configure wifi module", "wifi_apply_config")
  b.require("start wifi manager", "wifi_mgr")
  b.require("start http server", "http_srv")
  b.require("start web admin portal", "web_portal")
  b.require("start OTA rest api", "web_ota")
  b.require("start HomeAssistant rest api", "web_ha")
  b.require("telnet", "telnet")
  b.require("start thermostat", "thermostat")
  -- b.fnc(
  --   "gc at the end",
  --   function()
  --     function dumpLoaded()
  --       local log = require("log")
  --       log.print(package.loaded)
  --     end

  --     function heap()
  --       print(node.heap())
  --     end

  --     collectgarbage()
  --     collectgarbage()
  --   end
  -- )

  -- TODO add here more startup functions

  b.start()
end

-- delay starting boot up init logic with 1sec,
-- just in time to issue `file.remove("init.lc")` in case of desperate needs
require("tmr").create():alarm(1000, 0, main)
