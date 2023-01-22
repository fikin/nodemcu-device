local modname = ...

---@return web_ha_entity_specs
local function main()
    package.loaded[modname] = nil

    return { { type = "light", spec = {
        key          = "lights-switch",
        name         = "Lights",
    } } }
end

return main
