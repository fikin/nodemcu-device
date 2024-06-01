--[[
    Relay switch
]]
local modname = ...

---@class relay_switch_cfg_data
---@field is_on boolean

---@class relay_switch_cfg
---@field relay relay_cfg
---@field data relay_switch_cfg_data

local function main()
    package.loaded[modname] = nil

    ---@type lights_switch_cfg
    local cfg = require("device-settings")("relay-switch")

    require("relay")(cfg.relay)
end

return main
