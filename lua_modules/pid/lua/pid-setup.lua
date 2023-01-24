--[[
    Called to store in device settings the PID coefficients.
]]
local modname = ...

---@return factory_settings*
local function getFactorySettings()
    return require("factory-settings")("pid")
end

---@param cfg pid_cfg
---@param Kp number
---@param Ki number
---@param Kd number
---@param SampleTimeMs integer
local function setCoefficients(cfg, Kp, Ki, Kd, SampleTimeMs)
    local sampleTimeSec = SampleTimeMs / 1000
    cfg.sampleTimeMs = SampleTimeMs
    cfg.kp = Kp
    cfg.ki = Ki * sampleTimeSec
    cfg.kd = Kd / sampleTimeSec
end

---@param cfg pid_cfg
---@param reverseDirection boolean
local function assignDirection(cfg, reverseDirection)
    cfg.reverseDirection = reverseDirection
    if reverseDirection then
        cfg.kp = 0 - cfg.kp
        cfg.ki = 0 - cfg.ki
        cfg.kd = 0 - cfg.kd
    end
end

---@param cfg pid_cfg
---@param Setpoint number
---@param Kp number
---@param Ki number
---@param Kd number
---@param SampleTimeMs integer
---@param outMax number
---@param outMin number
---@param reverseDirection boolean
---@param noOvershoot boolean
local function assignCfg(cfg, Setpoint, Kp, Ki, Kd, SampleTimeMs, outMax, outMin, reverseDirection, noOvershoot)
    cfg.Setpoint = Setpoint
    setCoefficients(cfg, Kp, Ki, Kd, SampleTimeMs)
    cfg.outMax = outMax
    cfg.outMin = outMin
    assignDirection(cfg, reverseDirection)
    cfg.noOvershoot = noOvershoot
end

---Configure PID.
---It persists these as device settings.
---@param Setpoint number
---@param Kp number
---@param Ki number
---@param Kd number
---@param SampleTimeMs integer
---@param outMax number
---@param outMin number
---@param reverseDirection boolean
---@param noOvershoot boolean
local function main(Setpoint, Kp, Ki, Kd, SampleTimeMs, outMax, outMin, reverseDirection, noOvershoot)
    package.loaded[modname] = nil

    local builder = getFactorySettings()
    assignCfg(builder.cfg, Setpoint, Kp, Ki, Kd, SampleTimeMs, outMax, outMin, reverseDirection, noOvershoot)
    builder:done()
end

return main
