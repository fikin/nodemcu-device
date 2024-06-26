local modname = ...

---@param changes relay_switch_cfg_data as comming from HA request
local function setFn(changes)
    local log = require("log")
    log.info("change settings to %s", log.json, changes)

    ---@type lights_switch_cfg
    local cfg = require("device-settings")("lights-switch")

    require("relay")(cfg.relay)(changes.is_on)
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
