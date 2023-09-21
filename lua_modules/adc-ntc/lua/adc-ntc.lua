--[[
    ADC reader for NTC connected to ADC input.

    R1 is connected to VCC and Rntc.
]]
local modname = ...

local adc = require("adc")

---@class adcNtc_cfg
---@field Rntc integer NTC resistance in Kohm
---@field R1 integer resistor 1 in Kohm
---@field VCC integer VCC in V
---@field A number Steinhart-Hart model coefficient
---@field B number Steinhart-Hart model coefficient
---@field C number  Steinhart-Hart model coefficient

---table with "adc" key and temperature in C.
---this is temp-sensor interface req.
---@alias adc_temp {[string]:number}

---@type adcNtc_cfg
local cfg = require("device-settings")(modname)

---natural logarithm approximation
---@param x number
---@return number
function ln(x) --natural logarithm function for x>0 real values
    local y = (x - 1) / (x + 1)
    local sum = 1
    local val = 1
    if (x == nil) then
        return 0
    end
    -- we are using limited iterations to acquire reliable accuracy.
    -- here its upto 10000 and increased by 2
    for i = 3, 10000, 2 do
        val = val * (y * y)
        sum = sum + (val / i)
    end
    return 2 * y * sum
end

---@param cnt integer how to many readinds to average
---@return number average value
local function readAvg(cnt)
    local t = 0
    for i = 1, cnt, 1 do
        t = t + adc.read(0)
    end
    return t / cnt
end

---@param onReadCb fun(adc_temp) callback when temps have been read
local function main(onReadCb)
    package.loaded[modname] = nil

    local dAdcValue = readAvg(10)
    local dVout = (dAdcValue * cfg.VCC) / 1023
    local dRth = (cfg.VCC * cfg.R1 / dVout) - cfg.R1
    -- Temperature in kelvin
    local t = (1 / (cfg.A + (cfg.B * ln(dRth)) + (cfg.C * (ln(dRth)) ^ 3)))
    -- Temperature in degree celsius
    t = t - 273.15

    onReadCb({ adc = t })
end

return main
