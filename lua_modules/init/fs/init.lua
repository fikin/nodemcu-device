--[[
  Main entrypoint when booting up the device
]]

---@class init_seq_cfg
---@field bootsequence string[]

---@param b bootprotect*
local function configureFromBootSequence(b)
  ---@type init_seq_cfg
  local cfg = require("device-settings")("init-seq")
  for _, m in pairs(cfg.bootsequence) do
    b.require(m, m)
  end
end

---device init sequence
---it initializes LFS and other modules and runs boot sequence
local function main()
  require("_lfs-init")() -- mandatory first, prepares NodeMCU and LFS

  package.loaded["init"] = nil -- this module gc

  -- device startup sequence
  local b = require("bootprotect")

  configureFromBootSequence(b)
  -- b.require("setup device settings", "user-settings")
  -- b.require("configure logger with stored device settings", "log-start")
  -- b.require("configure wifi module", "wifi-apply-config")
  -- b.require("start wifi manager", "wifi-mgr")
  -- b.require("start http server", "http-srv")
  -- b.require("telnet", "telnet")
  -- b.require("start temp sensor", "temp-sensor-start")
  -- b.require("start relay switch", "relay-switch-start")
  -- b.require("start lights switch", "lights-switch-start")
  -- b.require("start thermostat", "thermostat-start")

  -- TODO add here more startup functions

  b.start()
end

-- delay starting boot up init logic with 1sec,
-- just in time to issue `file.remove("init.lc")` in case of desperate needs
require("tmr").create():alarm(1000, 0, main)
