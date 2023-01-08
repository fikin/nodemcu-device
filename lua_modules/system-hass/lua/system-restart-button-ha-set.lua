local modname = ...

---@class hass_button_req
---@field action string

---handle HASS button request
---@param cmd hass_button_req
local function restartNode(cmd)
    if cmd.action == "restart" then
        local task = require("node").task
        task.post(task.MEDIUM_PRIORITY, node.restart)
    else
        local log = require("log")
        log.error("HASS unsupported action received : %s", log.json, cmd)
    end
end

---@param changes hass_button_req
local function main(changes)
    package.loaded[modname] = nil

    restartNode(changes)
end

return main
