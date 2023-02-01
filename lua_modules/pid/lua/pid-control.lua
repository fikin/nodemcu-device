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
---@field setpoint number
---@field outMax number
---@field outMin number
---@field reverseDirection boolean
---@field noOvershoot boolean

---@class pid_state
---@field cfg pid_cfg
---@field Input number
---@field Output number
---@field _lastInput number
---@field _integralI number

---@type pid_state
local state = require("state")("pid")

---@param val number
---@return number
local function adjustMinMax(val)
    return math.min(math.max(val, state.cfg.outMin), state.cfg.outMax)
end

local function doCompute()
    local error = state.cfg.setpoint - state.Input
    local dInput = state.Input - state._lastInput

    local p = (state.cfg.noOvershoot) and 0 or (state.cfg.kp * error)

    local i = state.cfg.ki * error
    local ip = (state.cfg.noOvershoot) and (state.cfg.kp * dInput) or 0
    state._integralI = adjustMinMax(state._integralI + i - ip)

    local d = state.cfg.kd * dInput

    state.Output = adjustMinMax(p + state._integralI - d)

    state._lastInput = state.Input
end

local function main()
    package.loaded[modname] = nil

    doCompute()
end

return main
