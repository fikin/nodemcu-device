---@class pidSim_obj
---@field _logger fun(...)
---@field _Kp number
---@field _Ki number
---@field _Kd number
---@field _sampletime integer
---@field _out_min number
---@field _out_max number
---@field _integral number
---@field _last_input number
---@field _last_output number
---@field _last_calc_timestamp integer
---@field _time fun():integer
local M = {}
M.__index = M

---@return pidSim_obj
local function newInst()
    return setmetatable({
        _logger = nil,
        _Kp = 0,
        _Ki = 0,
        _Kd = 0,
        _sampletime = 0,
        _out_min = 0,
        _out_max = 0,
        _integral = 0,
        _last_input = 0,
        _last_output = 0,
        _last_calc_timestamp = 0,
        _time = nil,
    }, M)
end

---initialize PID controller Instance.
---@param self pidSim_obj
---@param sampletime number
---@param kp number
---@param ki number
---@param kd number
---@param out_min number
---@param out_max number
---@param time fun():integer
---@return pidSim_obj
local function init(self, sampletime, kp, ki, kd, out_min, out_max, time)
    self._logger = function(...) print(string.format(...)); end
    self._Kp = kp
    self._Ki = ki * sampletime
    self._Kd = kd / sampletime
    self._sampletime = sampletime * 1000
    self._out_min = out_min
    self._out_max = out_max
    self._integral = 0
    self._last_input = 0
    self._last_output = 0
    self._last_calc_timestamp = 0
    self._time = time
    return self
end

---@param val number
---@param low number
---@param high number
---@return boolean
local function inBetween(val, low, high)
    return val > low and val < high
end

---Adjusts and holds the given setpoint.
---@param self pidSim_obj
---@param input_val number The input value.
---@param setpoint number The target value.
---@return number power A value between `out_min` and `out_max`.
M.calc = function(self, input_val, setpoint)
    local now = self._time() * 1000

    if (now - self._last_calc_timestamp) < self._sampletime then
        return self._last_output
    end

    -- Compute all the working error variables
    local error = setpoint - input_val
    local input_diff = input_val - self._last_input

    -- In order to prevent windup, only integrate if the process is not saturated
    if inBetween(self._last_output, self._out_min, self._out_max) then
        self._integral = self._integral + (self._Ki * error)
        self._integral = math.min(self._integral, self._out_max)
        self._integral = math.max(self._integral, self._out_min)
    end

    local p = self._Kp * error
    local i = self._integral
    local d = -(self._Kd * input_diff)

    -- Compute PID Output
    self._last_output = p + i + d
    self._last_output = math.min(self._last_output, self._out_max)
    self._last_output = math.max(self._last_output, self._out_min)

    -- Log some debug info
    self._logger("P: %.2f , I: %.2f , D: %.2f , output: %.2f", p, i, d, self._last_output)

    -- Remember some variables for next time
    self._last_input = input_val
    self._last_calc_timestamp = now
    return self._last_output
end

---tmr.now() returned as seconds
---@return integer
local function nowSec()
    return math.floor(require("tmr").now() / 1000)
end

---Instantiate a proportional-integral-derivative controller.
---@param sampletime number The interval between calc() calls.
---@param kp number Proportional coefficient.
---@param ki number Integral coefficient.
---@param kd number Derivative coefficient.
---@param out_min number Lower output limit. By default -math.huge.
---@param out_max number Upper output limit. By default math.huge.
---@param time? fun():integer A function which returns the current time in seconds. By default refers to tmr.now().
---@return pidSim_obj
local function main(sampletime, kp, ki, kd, out_min, out_max, time)

    return init(
        newInst(),
        sampletime, kp, ki, kd,
        (out_min or -math.huge),
        (out_max or math.huge),
        (time or nowSec))
end

return main
