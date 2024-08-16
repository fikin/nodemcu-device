--[[
  Main entrypoint when booting up the device
]]
local modname = ...

---@class init_seq_cfg
---@field bootsequence string[]

---device init sequence
---it initializes LFS and other modules and runs boot sequence
local function bootSequence()
  package.loaded[modname] = nil -- this module gc

  -- mandatory first, prepares NodeMCU and LFS
  require("_lfs-init")()

  require("boot-seq")()
end

local function main()
  local tmr = require("tmr")
  -- delay starting boot up init logic with 1sec,
  -- just in time to issue `file.remove("init.lc")` in case of desperate needs
  tmr.create():alarm(1000, tmr.ALARM_SINGLE, bootSequence)
end

main()
