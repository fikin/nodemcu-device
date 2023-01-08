--[[
    Temperature sensor.
]]
local modname = ...

---@class relay_switch_cfg_data
---@field is_on boolean

---@class relay_switch_cfg
---@field pin integer
---@field data relay_switch_cfg_data

---prepare initial RTE state out of device settings
local function prepareRteState()
    -- read device settings into RTE state variable
    ---@type relay_switch_cfg
    local state = require("device-settings")("relay-switch")
    state.data = { is_on = false }

    -- remember in RTE state
    require("state")("relay-switch", state)
end

local function main()
    package.loaded[modname] = nil

    local log = require("log")
    log.debug("starting up ...")

    prepareRteState()

    require("relay-switch-control")(false)
end

return main
