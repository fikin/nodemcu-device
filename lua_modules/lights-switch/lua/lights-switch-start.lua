--[[
    Relay switch
]]
local modname = ...

---@class lights_switch_cfg_data
---@field is_on boolean

---@class lights_switch_cfg
---@field pin integer
---@field data relay_switch_cfg_data

local mn = "lights-switch"

---setup initial state
---@return lights_switch_cfg
local function setupInitialState()
    local cfg = require("device-settings")(mn)
    local state = require("state")(mn, cfg)
    state.data.is_on = false
    return state
end

local function main()
    package.loaded[modname] = nil

    local state = setupInitialState()
    require("lights-switch-ha-set")({ [mn] = state.data })
end

return main
