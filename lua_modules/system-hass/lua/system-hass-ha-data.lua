local modname = ...

---@return web_ha_entity_data
local function main()
    package.loaded[modname] = nil

    return {
        ["system-heap-sensor"] = {
            native_value = require("node").heap()
        }
    }
end

return main
