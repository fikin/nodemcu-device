local modname = ...

---@class hass_button_req
---@field action string

---handle HASS button request
---@param cmd hass_button_req
local function restartNode(cmd)
    local log = require("log")
    if cmd.action == "restart" then
        log.info("HASS (user) requested node restart, scheduling in 300ms ...")
        local tmr = require("tmr")
        tmr:create():alarm(300, tmr.ALARM_SINGLE, function()
            require("node").restart()
        end)
    else
        log.error("HASS unsupported action received : %s", log.json, cmd)
    end
end

---@param data table
local function main(data)
    package.loaded[modname] = nil

    local changes = data["system-restart-button"]
    if changes then
        restartNode(changes)
        return true
    else
        return false
    end
end

return main
