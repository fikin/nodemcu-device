--[[
  Manager of various HomeAssistant entities, registered with this device.

  Each entity is recognized by "key", which is accidentially is named
  after "{<key>: {...entity data...}}" inside data payload.
]]
local modname = ...

---@alias web_ha_set_fn fun(changes:table)
---@alias web_ha_spec_data table|fun():table

---contains all registered HA Entities
---@class web_ha_entity*

---register HA entity
---@param key string is data-payload attribute name
---@param specType string is one of HA NodeMCU-Device supported entity types
---@param spec web_ha_spec_data is returning HA NodeMCU-Device payload (entity specification)
---@param data web_ha_spec_data is returning HA NodeMCU-Device payload (entity data)
---@param setFn web_ha_set_fn|nil is fnc(changes) accepting content of {<key>: <content>} when HA sends update command
local function main(key, specType, spec, data, setFn)
  package.loaded[modname] = nil

  ---@type web_ha_entity*
  local state = require("state")(modname, {})

  ---@type {[string]:web_ha_spec_data}
  state.specTypes = state.specTypes or {}
  state.specTypes[specType] = state.specTypes[specType] or {}
  for i, v in pairs(state.specTypes[specType]) do
    if v.key == key then
      table.remove(state.specTypes[specType], i)
      break
    end
  end
  table.insert(state.specTypes[specType], spec)

  ---@type {[string]:web_ha_spec_data}
  state.data = state.data or {}
  state.data[key] = data

  ---@type {[string]:web_ha_set_fn}
  state.set = state.set or {}
  state.set[key] = setFn
end

return main
