local modname = ...

---@return web_ha_entity_data
local function main()
    package.loaded[modname] = nil

    ---@type temp_sensor_cfg
    local cfg = require("state")("temp-sensor")
    return { ["temp-sensor"] = cfg.data }
end

return main
