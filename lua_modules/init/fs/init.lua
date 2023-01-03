--[[
  Main entrypoint when booting up the device
]]

---device init sequence
---it initializes LFS and other modules and runs boot sequence
local function main()
  require("_lfs-init")() -- mandatory first, prepares NodeMCU and LFS

  package.loaded["init"] = nil -- this module gc

  -- device startup sequence
  local b = require("bootprotect")

  b.require("setup device settings", "device-settings-start")
  b.require("configure logger with stored device settings", "log-start")
  b.require("keep time up to date when connected to network", "sntp-sync-start")
  b.require("configure wifi module", "wifi-apply-config")
  b.require("start wifi manager", "wifi-mgr")
  b.require("start http server", "http-srv")
  b.require("start web admin portal", "web-portal")
  b.require("start OTA rest api", "web-ota")
  b.require("start HomeAssistant rest api", "web-ha")
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
