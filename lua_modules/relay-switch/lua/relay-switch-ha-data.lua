local modname = ...

--@return web_ha_entity_data
local function main()
    package.loaded[modname] = nil

    ---@type lights_switch_cfg
    local cfg = require("device-settings")("relay-switch")

    cfg.data = { is_on = require("relay")(cfg.relay)() }

    return { ["relay-switch"] = cfg.data }
end

return main
