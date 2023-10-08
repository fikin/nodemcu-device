--[[
    DS18b20 temperature sensor connected over OW.

    This implementation supports:
        - DS18B20 or DS19B20 familiy of sensors
        - wired in "power" mode (not "parasitic")

    Internally it uses a coroutine to suspend the execution when time delay is needed.
]]
local modname = ...

local log = require("log")
local ow = require("ow")
local task = require("node").task
local tmr = require("tmr")

local DS18B20FAMILY = 0x28
local DS1920FAMILY = 0x10 -- and DS18S20 series
-- local READ_ROM = 0x33
local CONVERT_T = 0x44
local READ_SCRATCHPAD = 0xBE
local READ_POWERSUPPLY = 0xB4
local MODE = 1

---converts ow sensor addr to string representation
---@param addr string
---@return string
local function addrToStr(addr)
    if type(addr) == "string" and #addr == 8 then
        return ("%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X "):format(addr:byte(1, 8))
    else
        return tostring(addr)
    end
end

---@param addr string
---@param data string
---@return number
---@return number
---@return number
local function decodeTemp(addr, data)
    local crc, b9 = ow.crc8(string.sub(data, 1, 8)), data:byte(9)

    local t = (data:byte(1) + data:byte(2) * 256)
    -- t is actually signed so process the sign bit and adjust for fractional bits
    -- the DS18B20 family has 4 fractional bits and the DS18S20s, 1 fractional bit
    t = ((t <= 32767) and t or t - 65536) * ((addr:byte(1) == DS18B20FAMILY) and 625 or 5000)
    t = t / 10000

    return crc, b9, t
end

---@param rawTemps {[string]:string}
---@return ds18b20_temps
local function decodeTemps(rawTemps)
    local tbl = {}
    for addr, data in pairs(rawTemps) do
        local crc, b9, t = decodeTemp(addr, data)
        if math.floor(t) ~= 85 then
            if crc == b9 then
                tbl[addrToStr(addr)] = t
            else
                log.error("%s temp crc failed", addrToStr, addr)
            end
        else
            log.error("sensor %s provided no conversion result", addrToStr, addr)
        end
    end
    return tbl
end

---@param pin integer
---@param addr string
---@return boolean
local function wiredInPowerMode(pin, addr)
    ow.reset(pin)
    ow.select(pin, addr)
    ow.write(pin, READ_POWERSUPPLY, MODE)
    return ow.read(pin) == 0 and false or true
end

---@param pin integer
---@param addr string
---@return boolean
local function assertSensor(pin, addr)
    local crc = ow.crc8(addr:sub(1, 7))
    if crc ~= addr:byte(8) then
        log.error(string.format("sensor %s crc check failed", addrToStr(addr)))
        return false
    end
    if (addr:byte(1) ~= DS1920FAMILY) and (addr:byte(1) ~= DS18B20FAMILY) then
        log.error("sensor %s is not a supported DS18B20 nor DS19B20 family but %02X",
            addrToStr(addr), addr:byte(1))
        return false
    end
    if not wiredInPowerMode(pin, addr) then
        log.error("sensor %s is powered in parasitic mode, use on own risk", addrToStr, addr)
    end
    return true
end

---@param pin integer
---@param addrs string[]
---@returns string[] addrs valid only
local function assertSensors(pin, addrs)
    local lst = {}
    for i, addr in ipairs(addrs) do
        if assertSensor(pin, addr) then
            table.insert(lst, addr)
        end
    end
    return lst
end

---@param pin integer
---@return string[]
local function readAddrs(pin)
    ow.reset_search(pin)
    ow.reset(pin)
    local lst = {}
    while true do
        local addr = ow.search(pin)
        if addr == nil then break end
        table.insert(lst, addr)
    end
    return lst
end

---@param pin integer
---@param addr string
local function startConversion(pin, addr)
    ow.reset(pin)
    ow.select(pin, addr)
    ow.write(pin, CONVERT_T, MODE)
end

---@param pin integer
---@param addrs string[]
local function startConversions(pin, addrs)
    for _, addr in ipairs(addrs) do
        startConversion(pin, addr)
    end
end

---@param pin integer
---@param addr string
---@return string
local function readRawTemp(pin, addr)
    ow.reset(pin)
    ow.select(pin, addr)
    ow.write(pin, READ_SCRATCHPAD, MODE)
    return ow.read_bytes(pin, 9)
end

---@param pin integer
---@param addrs string[]
---@return {[string]:string}
local function readRawTemps(pin, addrs)
    local tbl = {}
    for _, addr in ipairs(addrs) do
        tbl[addr] = readRawTemp(pin, addr)
    end
    return tbl
end

---read temps after conversion
---@param o ds18b20_struct
local function readTempsAfterConversions(o)
    local rawTemps = readRawTemps(o.pin, o.validAddrs)
    local temps = decodeTemps(rawTemps)
    ow.depower(o.pin)
    o.cb(temps)
end

---suspend the thread until node.taks revives it back.
---@param o ds18b20_struct
---@param delay? integer
local function wait(o)
    local f = function() readTempsAfterConversions(o) end
    if o.delay then
        tmr.create():alarm(o.delay, tmr.ALARM_SINGLE, f)
    else
        task.post(task.LOW_PRIORITY, f)
    end
end

---@param o ds18b20_struct
local function readT(o)
    ow.setup(o.pin)
    o.discoveredAddrs = readAddrs(o.pin)
    o.validAddrs = assertSensors(o.pin, o.discoveredAddrs)
    startConversions(o.pin, o.validAddrs)
    wait(o, o.delay)
end

local function main(pin, delay)
    package.loaded[modname] = nil

    local prn = function(o)
        log.info("read : %s", log.json, o)
    end

    local callState = {
        pin = pin,
        delay = delay,
        cb = prn,
        discoveredAddrs = nil,
        validAddrs = nil,
    }

    readT(callState)
    return callState
end

return main
