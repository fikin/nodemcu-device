--[[
Boot sequence for the device.

It uses first the `init-seq` configuration to load the modules in the order.
Then it uses the `devices-list` configuration to load the devices in the order.
]]
local modname = ...

---@param b bootprotect*
local function configureFromInitSequence(b)
  ---@type init_seq_cfg
  local cfg = require("device-settings")("init-seq")
  for _, m in ipairs(cfg.bootsequence) do
    b.require(m, m)
  end
end

---@param b bootprotect*
local function configureFromDevicesList(b)
  local lst = require("device-settings")("devices-list")
  for _, n in ipairs(lst) do
    b.fnc(n, function()
      require(string.format("dev-%s", n))(nil, true)
    end)
  end
end

local function main()
  package.loaded[modname] = nil

  -- device startup sequence
  local b = require(_G["BOOTPROTECT"] or "bootprotect")

  configureFromInitSequence(b)
  configureFromDevicesList(b)

  b.start()
end

return main
