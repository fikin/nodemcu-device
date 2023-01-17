--[[
    Temperature sensor.
]]
local modname = ...

---@return relay_switch_cfg
local function getState()
    return require("state")("relay-switch")
end

---@return web_ha_entity_data
local function main()
    package.loaded[modname] = nil
    
    return { ["relay-switch"] = getState().data }
end

return main
