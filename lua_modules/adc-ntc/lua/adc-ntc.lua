--[[
    ADC reader for NTC connected to ADC input.

    R1 is connected to VCC and Rntc.
]]
local modname = ...

local adc = require("adc")

---@class adcNtc_cfg
---@field AdcCorr integer correction factor for read ADC values. 1 means no correction.
---@field VccA0 integer max voltage at A0 input i.e 3.3V for NodeMCU and 1V for ESP8266
---@field VccR1 integer voltage at R1 i.e 5V or 3.3V
---@field R1 integer resistor 1 in Kohm
---@field A number Steinhart-Hart model coefficient
---@field B number Steinhart-Hart model coefficient
---@field C number  Steinhart-Hart model coefficient

---table with "adc" key and temperature in C.
---this is temp-sensor interface req.
---@alias adc_temp {[string]:number}

---@type adcNtc_cfg
local cfg = require("device-settings")(modname)

---@param cnt integer how to many readinds to average
---@return number average value
local function readAvg(cnt)
    local t = 0
    for _ = 1, cnt, 1 do
        t = t + adc.read(0)
    end
    return t / cnt
end

---@param onReadCb fun(temp:adc_temp) callback when temps have been read
local function main(onReadCb)
    package.loaded[modname] = nil

    local Vstep = cfg.VccA0 / 1024
    local AdcValue = readAvg(20) + cfg.AdcCorr
    local Vntc = Vstep * AdcValue
    local Rntc = cfg.R1 * Vntc / (cfg.VccR1 - Vntc)
    local LogRntc = math.log(Rntc)
    local bVal = cfg.B * LogRntc
    local cVal = cfg.C * LogRntc * LogRntc * LogRntc
    -- Temperature in kelvin
    local tK = 1 / (cfg.A + bVal + cVal)
    -- Temperature in degree celsius
    local tC = tK - 273.15
    -- Temperature in Farenheit
    -- local tF = (tC * 9.0)/ 5.0 + 32.0;
    -- require("log").debug("AdcValue=%f Vntc=%f Rntc=%f logRntc=%f bVal=%f cVal=%f tK=%f",
    --     AdcValue, Vntc, Rntc, LogRntc, bVal, cVal, tK)

    onReadCb({ adc = tC })
end

return main
