--[[
    Called at device startup time to prepare PID state out of device settings.

    it starts up control loop.
]]
local modname = ...

---@return pid_state
local function initState()
    ---@type pid_cfg
    local cfg = require("device-settings")("pid")

    ---@type pid_state
    local def = {
        Input = 0,
        Output = 0,
        _lastInput = 0,
        _integralI = 0,
    }
    ---@type pid_state
    local state = require("state")("pid", def)

    state.cfg = cfg

    -- init part
    state._lastInput = state.Input
    state._integralI = state.Output

    return state
end

local function controlLoopFn()
    require("pid-control")()
end

---@param delayMs integer
local function scheduleControlLoop(delayMs)
    local tmr = require("tmr")
    local t = tmr.create()
    if not t:alarm(delayMs, tmr.ALARM_AUTO, controlLoopFn) then
        require("log").error("failed to start PID control loop timer")
    end
end

local function main()
    package.loaded[modname] = nil

    local cfg = initState()
    scheduleControlLoop(cfg.cfg.sampleTimeMs)
end

return main
