--[[
    Assign new PID setpoint
]]
local modname = ...

---@return pid_state
local function getState()
    return require("state")("pid")
end

---assigns PID's setpoint value
---@param setpoint number
local function main(setpoint)
    package.loaded[modname] = nil

    getState().cfg.setpoint = setpoint

    local b = require("factory-settings")("pid")
    b.cfg.setpoint = setpoint
    b:done()
end

return main
