--[[
    Returns current timestamp in the format "YYYY-MM-DDTHH:MI:SS"
    using rtctime module.
]]

local modname = ...

---returns timestamp from rtctime
---@return string
local function main()
    package.loaded[modname] = nil

    local rtctime = require("rtctime")
    local sec, _, _ = rtctime.get()
    local tm = rtctime.epoch2cal(sec)
    return string.format(
        "%04d-%02d-%02dT%02d:%02d:%02d",
        tm.year,
        tm.mon, -- this rtctime field name, not osdate
        tm.day,
        tm.hour,
        tm.min,
        tm.sec
    )
end

return main
