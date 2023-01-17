--[[
    Relay switch
]]
local modname = ...

---@class relay_switch_cfg_data
---@field is_on boolean

---@class relay_switch_cfg
---@field pin integer
---@field data relay_switch_cfg_data

local function main()
    package.loaded[modname] = nil

    local log = require("log")
    log.debug("starting up ...")

    require("relay-switch-ha-set")({ is_on = false })
end

return main
