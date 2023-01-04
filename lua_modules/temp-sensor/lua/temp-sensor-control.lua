local modname = ...

---@return temp_sensor_cfg
local function getState()
    return require("state")("temp-sensor")
end

local function getTemp()
    package.loaded[modname] = nil

    local state = getState()
    return state.data.native_value
end

return getTemp
