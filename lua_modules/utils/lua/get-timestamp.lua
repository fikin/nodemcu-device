--[[
    Returns current timestamp in the format "YYYY-MM-DDTHH:MI:SS"
    using rtctime module.
]]

local modname = ...

---returns timestamp from rtctime
---@param sec integer|nil sec in unix epoch
---@return string
---@return integer sec in unix epoch
local function main(sec)
    package.loaded[modname] = nil

    local rtctime = require("rtctime")
    sec = sec or (function()
        local _sec, _, _ = rtctime.get()
        return _sec
    end)()
    local tm = rtctime.epoch2cal(sec)
    return string.format(
        "%04d-%02d-%02dT%02d:%02d:%02d",
        tm.year,
        tm.mon, -- this rtctime field name, not osdate
        tm.day,
        tm.hour,
        tm.min,
        tm.sec
    ), sec
end

return main
