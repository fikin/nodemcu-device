local modname = ...

---@return web_ha_entity_specs
local function main()
    package.loaded[modname] = nil

    return { { type = "switch", spec = {
        key          = "relay-switch",
        name         = "Relay",
        device_class = "switch",
    } } }
end

return main
