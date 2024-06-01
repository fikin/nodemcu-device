local modname = ...

local tmr = require("tmr")
local gpio = require("gpio")

---returns fun():integer, which represents duration in tmr.now() time
---b/n moment of calling this function and returned one.
---@return fun():integer
local function durationBetweenCalls()
    local lastCall = tmr.now()
    return function()
        local now = tmr.now()
        local delta = now - lastCall
        if delta < 0 then
            delta = delta + 2147483647
        end
        lastCall = now
        return delta
    end
end

local secondSize = 1000000

---@class vetinari_const
---@field minuteSize         integer
---@field tickSize           integer
---@field oneAndHalfTickSize integer
---@field oneAndHalfSec      integer

---@type vetinari_const
local _constants = {
    minuteSize = secondSize * 60,
    tickSize = secondSize / 2,               -- hand moves 2x faster than normal
    oneAndHalfTickSize = secondSize * 3 / 4, -- tickSize x 1.5
    oneAndHalfSec = secondSize * 3 / 2       -- secondSize x 1.5
}

---@class vetinari_vars
---@field remainingTime  integer
---@field movesToMake integer

---@type vetinari_vars
local _vars = {
    remainingTime = 0,
    movesToMake = -1000
}

---should the secons's hand move or stay?
---@param constants vetinari_const
---@param vars vetinari_vars
---@return boolean
local function shouldHandMove(constants, vars)
    if vars.movesToMake == 1 then
        return vars.remainingTime < constants.oneAndHalfTickSize
    end

    if vars.remainingTime <= (vars.movesToMake * constants.tickSize) then
        return true
    else
        return math.random(0, 1) < 0.3 -- <30% chance to move
    end
end

---recalculate remaining duration wetween two consequent calls
---@param constants vetinari_const
---@param vars vetinari_vars
---@param calcDurationFn fun():integer
---@return integer
local function recalc(constants, vars, calcDurationFn)
    local d = calcDurationFn() -- duration from previoud call here
    if vars.movesToMake == -1000 or vars.movesToMake == 0 then
        d = 0
        if vars.movesToMake == -1000 then
            vars.remainingTime = constants.minuteSize
            vars.movesToMake = 60
        else
            vars.remainingTime = constants.minuteSize - vars.remainingTime
            vars.movesToMake = 60
        end
    end
    return d
end

---advance the time
---@param vars vetinari_vars
---@param duration integer
---@param shouldMove boolean
local function advance(vars, duration, shouldMove)
    vars.remainingTime = vars.remainingTime - duration
    if shouldMove then
        vars.movesToMake = vars.movesToMake - 1
    end
end

---should second's hand move or stay
---@return fun():boolean
local function shouldMoveSecondsHand()
    local calcDuration = durationBetweenCalls() -- start time of duration tracking

    return function()
        local d = recalc(_constants, _vars, calcDuration)
        local flg = shouldHandMove(_constants, _vars)
        advance(_vars, d, flg)
        return flg
    end
end

---toggle the clock's coil
---@param coilPins integer[]
---@return fun(integer)
local function toggleCoil(coilPins)
    assert(type(coilPins) == "table")
    assert(type(coilPins[1]) == "number", type(coilPins[1]))
    assert(type(coilPins[2]) == "number", type(coilPins[1]))
    assert(coilPins[0] ~= coilPins[1])
    gpio.mode(coilPins[1], gpio.OUTPUT, gpio.PULLUP)
    gpio.mode(coilPins[2], gpio.OUTPUT, gpio.PULLUP)
    local pinIndx = 1
    local lastLevel = 0
    return function(setToLevel)
        if setToLevel == gpio.LOW and lastLevel == gpio.LOW then
            return
        end
        assert(setToLevel ~= gpio.HIGH or lastLevel ~= setToLevel, "missed toggle(gpio.LOW) call somewhere")
        if setToLevel == gpio.HIGH then
            pinIndx = 1 - pinIndx
        end
        gpio.write(coilPins[pinIndx + 1], setToLevel)
        lastLevel = setToLevel
    end
end

---count n-th times, return true, otherwise false, start from 1 when count is over
---@param nthCall integer
---@return fun():boolean true if function calls == n-th, else fase
local function trueOnNCall(nthCall)
    local cnt = 0
    return function()
        cnt = cnt + 1
        if cnt > nthCall then
            cnt = 1
        end
        return cnt == nthCall
    end
end

---fire single alarm after time
---@param delayMs integer
---@param fnc fun(t:tmr_instance)
local function fireAfter(delayMs, fnc)
    local t = tmr.create()
    t:register(delayMs, tmr.ALARM_SINGLE, fnc)
    t:start()
end

---fire repeating alarm
---@param delayMs integer
---@param fnc fun(t:tmr_instance)
local function fireEvery(delayMs, fnc)
    local t = tmr.create()
    t:register(delayMs, tmr.ALARM_AUTO, fnc)
    t:start()
end

---control "loud" clock, whose second's hand moves with 1Hz coil frequency
---@param coilPins integer[]
local function loudClock(coilPins)
    local coilFnc = toggleCoil(coilPins)
    local moveHandFnc = shouldMoveSecondsHand()
    fireEvery(
        500,
        function()
            if moveHandFnc() then
                coilFnc(gpio.HIGH)
            end
        end
    )
    fireEvery(
        120,
        function()
            coilFnc(gpio.LOW)
        end
    )
end

---control "silent" clock, whose second's hand moves with 8Hz coil frequency
---@param coilPins integer[]
local function silentClock(coilPins)
    local coilFnc = toggleCoil(coilPins)
    local moveHandFnc = shouldMoveSecondsHand()
    local isNCallFnc = trueOnNCall(16)
    local moveFlg = false
    fireEvery(
        31,
        function()
            if moveFlg then
                coilFnc(gpio.HIGH)
            end
            if isNCallFnc() then
                moveFlg = moveHandFnc()
            end
        end
    )
    fireAfter(
        20,
        function()
            coilFnc(gpio.LOW)
            fireEvery(
                31,
                function()
                    coilFnc(gpio.LOW)
                end
            )
        end
    )
end

---control a clock
---@param typeOfClock string one or "sillent" or "loud"
---@return fun(pins:integer[]) control function
local function main(typeOfClock)
    package.loaded[modname] = nil

    if typeOfClock == "loud" then
        return loudClock
    elseif typeOfClock == "silent" then
        return silentClock
    elseif typeOfClock == "test" then
        return {
            shouldMoveSecondsHand = shouldMoveSecondsHand,
            toggleCoil = toggleCoil,
            trueOnNCall = trueOnNCall
        }
    else
        error("expected 'silent' or 'loud' clock type but found " .. typeOfClock)
    end
end

return main
