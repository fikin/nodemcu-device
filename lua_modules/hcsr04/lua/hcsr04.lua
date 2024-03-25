local modname = ...

---@class hcsr04_sensor_cfg
---@field triggerPin integer
---@field echoPin integer
---@field averageReads integer consequent reads to average, min 1
---@field impulseUs integer trigger signal length, def 10
---@field calibrationCoef integer callibration coeficient, def 1

local node, tmr, gpio, scheduler = require("node"), require("tmr"), require("gpio"), require("scheduler")

-- speed of sound in air at 20C is about 343m/s
-- metrics conversion to mm/us = (100cm * 10mm) / (1000ms * 1000us)
-- converted to one CPU tick (ccount) based on mm/us
-- divided by 2 because the meassured time duration includes both directions of sound travel
local tickMmUs = 0.343 * node.getcpufreq() / 2

local key = math.random(1024)

---@param cfg hcsr04_sensor_cfg
---@return number
local function meassureDistance(cfg)
    gpio.write(cfg.triggerPin, gpio.HIGH)
    node.delay(cfg.impulseUs)
    gpio.write(cfg.triggerPin, gpio.LOW)

    local ccountStart = tmr.ccount()
    local ccountEnd = scheduler:waitOrTimeout(key, 50)
    ccountEnd = ccountEnd or tmr.ccount()

    return math.abs(ccountEnd - ccountStart) * cfg.calibrationCoef / tickMmUs
end

---average distance reads
---@param cfg hcsr04_sensor_cfg
---@return number
local function meassureAverage(cfg)
    local sum = 0
    for _ = 0, cfg.averageReads do
        sum = sum + meassureDistance(cfg)
    end

    return sum / cfg.averageReads
end

---@param cfg hcsr04_sensor_cfg
local function performMeassurement(cfg)
    gpio.mode(cfg.triggerPin, gpio.OUTPUT)
    gpio.mode(cfg.echoPin, gpio.INPUT)

    gpio.trig(cfg.echoPin, "both", function() scheduler:signal(key, tmr.ccount()) end)

    local distance = meassureAverage(cfg)

    gpio.trig(cfg.echoPin, "none", nil)

    return distance
end

---@param cfg hcsr04_sensor_cfg|nil
---@return number distance in meters
local function main(cfg)
    package.loaded[modname] = nil

    cfg = cfg or require("device-settings")(modname)

    return performMeassurement(cfg)
end

return main
