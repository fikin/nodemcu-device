local modname = ...

---@alias hcsr04_sensor_reading_cb fun(distanceMm:number)

---@class hcsr04_sensor_cfg
---@field triggerPin integer
---@field echoPin integer
---@field averageReads integer consequent reads to average, min 1
---@field impulseUs integer trigger signal length, def 10
---@field calibrationCoef integer callibration coeficient, def 1

local node, tmr, gpio = require("node"), require("tmr"), require("gpio")

-- speed of sound in air at 20C is about 343m/s
-- metrics conversion to mm/us = (100cm * 10mm) / (1000ms * 1000us)
-- converted to one CPU tick (ccount) based on mm/us
-- divided by 2 because the meassured time duration includes both directions of sound travel
local tickMmUs = 0.343 * node.getcpufreq() / 2

--- configuration as provided by caller
---@type hcsr04_sensor_cfg
local cfg = require("device-settings")(modname)

--- callback to pass the read distance as provided by caller
---@type hcsr04_sensor_reading_cb
local onReadingCb

--- coroutine created to read one caller request
---@type thread
local co
--- timeout protection against indefinite distances
---@type tmr_instance
local tm

local function yieldCcount()
    if co and coroutine.status(co) == "suspended" then
        coroutine.resume(co, tmr.ccount())
    end
end

local function meassureDistance()
    if not tm:start() then error("failed starting hcsr04 timeout timer") end

    gpio.write(cfg.triggerPin, gpio.HIGH)
    node.delay(cfg.impulseUs)
    gpio.write(cfg.triggerPin, gpio.LOW)

    local ccountStart = coroutine.yield()
    local ccountEnd = coroutine.yield()

    tm:stop()

    return math.abs(ccountEnd - ccountStart) * cfg.calibrationCoef / tickMmUs
end

---average distance reads
---@return number
local function meassureAverage()
    local sum = 0
    for _ = 0, cfg.averageReads do
        sum = sum + meassureDistance()
    end

    return sum / cfg.averageReads
end

local function performMeassurement()
    gpio.mode(cfg.triggerPin, gpio.OUTPUT)
    gpio.mode(cfg.echoPin, gpio.INPUT)

    gpio.trig(cfg.echoPin, "both", yieldCcount)

    -- indefinite distance protection, set to 50ms i.e. ~ 17m
    tm = tmr.create()
    tm:register(50, tmr.ALARM_AUTO, yieldCcount)

    local distance = meassureAverage()

    -- tear down sequence
    tm:unregister()
    gpio.trig(cfg.echoPin, "none", nil)

    onReadingCb(distance)
end

---@param onReadingCb1 hcsr04_sensor_reading_cb
local function main(onReadingCb1)
    package.loaded[modname] = nil

    onReadingCb = onReadingCb1

    co = coroutine.create(performMeassurement)
    coroutine.resume(co)
end

return main