--[[
    Temperature sensor.
]]
local modname = ...

local log = require("log")

---@class relay_switch_cfg_data
---@field is_on boolean

---@class relay_switch_cfg
---@field pin integer
---@field data relay_switch_cfg_data

---@return relay_switch_cfg
local function getState()
    return require("state")(modname)
end

---called by web_ha to handle HA commands
---@param changes relay_switch_cfg_data as comming from HA request
local function setFn(changes)
    local log = require("log")
    log.info("change settings to %s", log.json, changes)
    require("relay-switch-control")(changes.is_on)
end

---prepare initial RTE state out of device settings
local function prepareRteState()
    -- read device settings into RTE state variable
    ---@type relay_switch_cfg
    local state = require("device-settings")(modname)
    state.data = { is_on = false }

    -- remember in RTE state
    require("state")(modname, state)
end

---register Home Assistant entity
local function registerHAentity()
    -- register HA entity
    local spec = {
        key          = modname,
        name         = "Relay",
        device_class = "switch",
    }
    local ptrToData = getState().data
    require("web-ha-entity")(modname, "switch", spec, ptrToData, setFn)
end

local function main()
    package.loaded[modname] = nil

    log.debug("starting up ...")

    prepareRteState()

    require("relay-switch-control")(false)

    registerHAentity()
end

return main
