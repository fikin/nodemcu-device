--[[
    Relay switch
]]
local modname = ...

---@class relay_switch_cfg_data
---@field is_on boolean

---@class relay_switch_cfg
---@field pin integer
---@field data relay_switch_cfg_data

---setup initial state
---@return relay_switch_cfg
local function setupInitialState()
    local mn = "relay-switch"
    local cfg = require("device-settings")(mn)
    local state = require("state")(mn, cfg)
    state.data = { is_on = false }
    return state
end

local function main()
    package.loaded[modname] = nil

    require("relay-switch-ha-set")(setupInitialState().data)
end

return main
