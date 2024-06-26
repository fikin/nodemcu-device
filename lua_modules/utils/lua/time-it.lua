local modname = ...

local function timeIt(cnt, fnc, ...)
    local tmr = require("tmr")
    local node = require("node")

    local function loopIt(f2, ...)
        local t0 = tmr.ccount()
        for _ = 1, cnt do
            f2(...)
        end
        local t1 = tmr.ccount()
        return math.ceil((t1 - t0) / cnt)
    end

    local emptyTime = loopIt(function()
    end)
    local deltaCPUTicks = math.abs(loopIt(fnc, ...) - emptyTime)
    local deltaUS = math.ceil(deltaCPUTicks / node.getcpufreq())

    return deltaCPUTicks, deltaUS
end

local function main(cnt, fnc, ...)
    package.loaded[modname] = nil

    return timeIt(cnt, fnc, ...)
end

return main
