local modname = ...

---@param changes relay_switch_cfg_data as comming from HA request
local function setFn(changes)
    local log = require("log")
    log.info("change settings to %s", log.json, changes)

    ---@type lights_switch_cfg
    local state = require("state")("lights-switch")
    state.data.is_on = changes.is_on
    require("gpio-set-pin")(state.pin, state.data.is_on)
end

---@param data table changes as they are coming from HASS
---@return boolean flag if recognizes the key, it returns true, otherwise false
local function main(data)
    package.loaded[modname] = nil

    local changes = data["lights-switch"]
    if changes then
        setFn(changes)
        return true
    end
    return false
end

return main
