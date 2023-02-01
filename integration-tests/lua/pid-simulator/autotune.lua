local dequeFact = require("mini-deque")
local round = require("round")

---@class autotuneCoeffients_obj
---@field kp number
---@field ki number
---@field kd number

---@class autotune_obj
local M = {
    PEAK_AMPLITUDE_TOLERANCE = 0.05,
    STATE_OFF = 'off',
    STATE_RELAY_STEP_UP = 'relay step up',
    STATE_RELAY_STEP_DOWN = 'relay step down',
    STATE_SUCCEEDED = 'succeeded',
    STATE_FAILED = 'failed',

    _tuning_rules       = {
        -- rule: [Kp_divisor, Ki_divisor, Kd_divisor]
        ["ziegler-nichols"] = { 34, 40, 160 },
        ["tyreus-luyben"] = { 44, 9, 126 },
        ["ciancone-marlin"] = { 66, 88, 162 },
        ["pessen-integral"] = { 28, 50, 133 },
        ["some-overshoot"] = { 60, 40, 60 },
        ["no-overshoot"] = { 100, 40, 60 },
        ["brewing"] = { 2.5, 6, 38 },
    },
    _logger             = function(...) print(string.format(...)); end,
    ---@type fun():integer
    _time               = nil,
    ---@type deque_obj
    _inputs             = nil,
    ---@type number
    _sampletime         = 0,
    ---@type number
    _setpoint           = 0,
    ---@type number
    _outputstep         = 0,
    ---@type number
    _noiseband          = 0,
    ---@type number
    _out_min            = 0,
    ---@type number
    _out_max            = 0,
    ---@type string
    _state              = "",
    ---@type deque_obj
    _peak_timestamps    = nil,
    ---@type deque_obj
    _peaks              = nil,
    ---@type number
    _output             = 0,
    ---@type number
    _last_run_timestamp = 0,
    ---@type number
    _peak_type          = 0,
    ---@type number
    _peak_count         = 0,
    ---@type number
    _initial_output     = 0,
    ---@type number
    _induced_amplitude  = 0,
    ---@type number
    _Ku                 = 0,
    ---@type number
    _Pu                 = 0,
}
M.__index = M

---@param setpoint number
---@param out_step number
---@param sampletime number
---@param lookback number
---@param out_min number
---@param out_max number
---@param noiseband number
---@param time fun():integer
---@return autotune_obj
local function newInst(setpoint, out_step, sampletime, lookback, out_min, out_max, noiseband, time)
    return setmetatable({
        _time = time,
        _inputs = dequeFact(round(lookback / sampletime)),
        _sampletime = sampletime * 1000,
        _setpoint = setpoint,
        _outputstep = out_step,
        _noiseband = noiseband,
        _out_min = out_min,
        _out_max = out_max,
        _state = M.STATE_OFF,
        _peak_timestamps = dequeFact(5),
        _peaks = dequeFact(5),
        _output = 0,
        _last_run_timestamp = 0,
        _peak_type = 0,
        _peak_count = 0,
        _initial_output = 0,
        _induced_amplitude = 0,
        _Ku = 0,
        _Pu = 0,
    }, M)
end

---@param self autotune_obj
---@return string
M.state = function(self)
    return self._state
end

---@param self autotune_obj
---@return number
M.output = function(self)
    return self._output
end

---List calculated tunning coefficients in case of successful tunning
---@param self autotune_obj
---@return {[string]:autotuneCoeffients_obj}
M.tuningResults = function(self)
    local arr = {}
    for rule, divisors in pairs(self._tuning_rules) do
        local kp = self._Ku / divisors[1]
        local ki = kp / (self._Pu / divisors[2])
        local kd = kp * (self._Pu / divisors[3])
        arr[rule] = { kp = kp, ki = ki, kd = kd, }
    end
    return arr
end

---@param self autotune_obj
---@param inputValue number
---@param timestamp number
local function _initTuner(self, inputValue, timestamp)
    self._peak_type = 0
    self._peak_count = 0
    self._output = 0
    self._initial_output = 0
    self._Ku = 0
    self._Pu = 0
    self._inputs:clear()
    self._peaks:clear()
    self._peak_timestamps:clear()
    self._peak_timestamps:append(timestamp)
    self._state = M.STATE_RELAY_STEP_UP
end

---check input and change relay state if necessary
---@param self autotune_obj
---@param input_val number
local function changeRelayState(self, input_val)
    -- check input and change relay state if necessary
    if (self._state == M.STATE_RELAY_STEP_UP) and (input_val > self._setpoint + self._noiseband) then
        self._state = M.STATE_RELAY_STEP_DOWN
        self._logger('switched state: %s', self._state)
        self._logger('input: %.2f', input_val)
    elseif (self._state == M.STATE_RELAY_STEP_DOWN) and (input_val < self._setpoint - self._noiseband) then
        self._state = M.STATE_RELAY_STEP_UP
        self._logger('switched state: %s', self._state)
        self._logger('input: %.2f', input_val)
    end
end

---@param self autotune_obj
---@return number
local function setOutput(self)
    local val = self._output
    if (self._state == M.STATE_RELAY_STEP_UP) then
        val = self._initial_output + self._outputstep
    elseif (self._state == M.STATE_RELAY_STEP_DOWN) then
        val = self._initial_output - self._outputstep
    end

    val = math.min(val, self._out_max)
    val = math.max(val, self._out_min)

    return val
end

---@param self autotune_obj
---@param input_val number
---@return boolean
---@return boolean
local function identifyPeaks(self, input_val)
    -- identify peaks
    local is_max = true
    local is_min = true

    for _, val in ipairs(self._inputs:peekItems()) do
        is_max = is_max and (input_val >= val)
        is_min = is_min and (input_val <= val)
    end

    return is_max, is_min
end

---@param self autotune_obj
---@param input_val number
---@param now integer
---@param is_max boolean
---@param is_min boolean
---@return boolean
local function detectInflectionPoint(self, input_val, now, is_max, is_min)
    local inflection = false

    -- peak types:
    -- -1: minimum
    -- +1: maximum
    if is_max then
        if self._peak_type == -1 then
            inflection = true
        end
        self._peak_type = 1
    elseif is_min then
        if self._peak_type == 1 then
            inflection = true
        end
        self._peak_type = -1
    end

    return inflection
end

local function onInflectionPoint(self, input_val, now, is_max, is_min)
    local inflection = detectInflectionPoint(self, input_val, now, is_max, is_min)

    -- update peak times and values
    if inflection then
        self._peak_count = self._peak_count + 1
        self._peaks:append(input_val)
        self._peak_timestamps:append(now)
        self._logger('found peak: %.2f', input_val)
        self._logger('peak count: %d', self._peak_count)
    end

    -- check for convergence of induced oscillation
    -- convergence of amplitude assessed on last 4 peaks (1.5 cycles)
    self._induced_amplitude = 0

    if inflection and (self._peak_count > 4) then
        local abs_max = self._peaks:itemAt(-2)
        local abs_min = self._peaks:itemAt(-2)
        for i = 1, (self._peaks:len() - 2) do
            local delta = math.abs(self._peaks:itemAt(i) - self._peaks:itemAt(i + 1))
            self._induced_amplitude = self._induced_amplitude + delta
            abs_max = math.max(self._peaks:itemAt(i), abs_max)
            abs_min = math.min(self._peaks:itemAt(i), abs_min)
        end

        self._induced_amplitude = self._induced_amplitude / 6.0

        -- check convergence criterion for amplitude of induced oscillation
        local amplitude_dev = (
            (0.5 * (abs_max - abs_min) - self._induced_amplitude) / self._induced_amplitude)

        self._logger('amplitude: %.2f', self._induced_amplitude)
        self._logger('amplitude deviation: %.2f', amplitude_dev)

        if amplitude_dev < M.PEAK_AMPLITUDE_TOLERANCE then
            self._state = M.STATE_SUCCEEDED
        end
    end
end

---@param self autotune_obj
local function onSuccess(self)
    self._output = 0

    -- calculate ultimate gain
    self._Ku = 4.0 * self._outputstep / (self._induced_amplitude * math.pi)

    -- calculate ultimate period in seconds
    local period1 = self._peak_timestamps:itemAt(4) - self._peak_timestamps:itemAt(2)
    local period2 = self._peak_timestamps:itemAt(5) - self._peak_timestamps:itemAt(3)
    self._Pu = 0.5 * (period1 + period2) / 1000.0
end

---@param self autotune_obj
local function onNextIter(self)
    self._output = 0
    self._state = M.STATE_FAILED
end

---To autotune a system, this method must be called periodically.
---@param self autotune_obj
---@param input_val number The input value.
---@return boolean `true` if tuning is finished, otherwise `false`.
M.run = function(self, input_val)
    local now = self._time() * 1000

    if (self._state == M.STATE_OFF)
        or (self._state == M.STATE_SUCCEEDED)
        or (self._state == M.STATE_FAILED) then
        _initTuner(self, input_val, now)
    elseif (now - self._last_run_timestamp) < self._sampletime then
        return false
    end

    self._last_run_timestamp = now

    -- check input and change relay state if necessary
    changeRelayState(self, input_val)

    -- set output
    self._output = setOutput(self)

    -- identify peaks
    local is_max, is_min = identifyPeaks(self, input_val)

    self._inputs:append(input_val)

    -- we don't want to trust the maxes or mins until the input array is full
    if self._inputs:len() < self._inputs:maxLen() then
        return false
    end

    onInflectionPoint(self, input_val, now, is_max, is_min)

    -- if the autotune has not already converged
    -- terminate after 10 cycles
    if self._peak_count >= 20 then
        onNextIter(self)
        return true
    end

    if self._state == M.STATE_SUCCEEDED then
        onSuccess(self)
        return true
    end

    return false
end

---tmr.now() returned as seconds
---@return integer
local function nowSec()
    return math.floor(require("tmr").now() / 1000)
end

---instantiate new autotune simulator object
---@param setpoint number
---@param out_step number
---@param sampletime number
---@param lookback number
---@param out_min number
---@param out_max number
---@param noiseband number
---@param time fun():integer
---@return autotune_obj
local function main(setpoint, out_step, sampletime, lookback, out_min, out_max, noiseband, time)
    return newInst(
        setpoint,
        (out_step or 10),
        (sampletime or 5),
        (lookback or 60),
        (out_min or -math.huge),
        (out_max or math.huge),
        (noiseband or 0.5),
        (time or nowSec)
    )
end

return main
