--[[
    Control loop of PID.

    Called periodically.
]]
local modname = ...

---@class pid_cfg
---@field kp number
---@field ki number
---@field kd number
---@field sampleTimeMs integer
---@field Setpoint number
---@field outMax number
---@field outMin number
---@field reverseDirection boolean
---@field noOvershoot boolean

---@class pid_state
---@field cfg pid_cfg
---@field Input number
---@field Output number
---@field lastInput number
---@field lastTime number
---@field outputSum number

---@return pid_state
local function getState()
    return require("state")("pid")
end

local state = getState()
local tmr = require("tmr")

---@param val number
---@return number
local function adjustMinMax(val)
    if val > state.cfg.outMax then
        return state.cfg.outMax
    elseif val < state.cfg.outMin then
        return state.cfg.outMin
    else
        return val
    end
end

local function doCompute()
    local error = state.cfg.Setpoint - state.Input
    local dInput = state.Input - state.lastInput

    state.outputSum = (state.outputSum) + (state.cfg.ki * error)
    if state.cfg.noOvershoot then
        state.outputSum = (state.outputSum) - (state.cfg.kp * dInput)
    end
    state.outputSum = adjustMinMax(state.outputSum)

    local outVal = 0
    if not state.cfg.noOvershoot then
        outVal = (state.cfg.kp * error)
    end
    outVal = (outVal) + (state.outputSum) - (state.cfg.kd * dInput)
    state.Output = adjustMinMax(outVal)

    state.lastInput = state.Input
end

local function main()
    package.loaded[modname] = nil

    local now = tmr.now()
    local timeChange = now - state.lastTime
    if timeChange >= state.cfg.sampleTimeMs then
        doCompute()
        state.lastTime = now;
    end
end

return main
