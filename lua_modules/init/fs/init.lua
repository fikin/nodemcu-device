--[[
  Main entrypoint when booting up the device
]]

---@class init_seq_cfg
---@field bootsequence string[]

---@param b bootprotect*
local function configureFromBootSequence(b)
  ---@type init_seq_cfg
  local cfg = require("device-settings")("init-seq")
  for _, m in ipairs(cfg.bootsequence) do
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

  b.start()
end

-- delay starting boot up init logic with 1sec,
-- just in time to issue `file.remove("init.lc")` in case of desperate needs
require("tmr").create():alarm(1000, 0, main)
