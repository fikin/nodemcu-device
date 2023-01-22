--[[
    Temperature sensor.
]]
local modname = ...

---@return relay_switch_cfg
local function getState()
    return require("state")("lights-switch")
end

---@return web_ha_entity_data
local function main()
    package.loaded[modname] = nil
    
    return { ["lights-switch"] = getState().data }
end

return main
