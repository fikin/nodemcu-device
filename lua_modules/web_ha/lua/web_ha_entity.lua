--[[
  Manager of various HomeAssistant entities, registered with this device.

  Each entity is recognized by "key", which is accidentially is named
  after "{<key>: {...entity data...}}" inside data payload.
]]
local modname = ...

---contains all registered HA Entities
---@class web_ha_entity*
---@field specTypes table containing specs of all registered entities
---@field data table containing data of all registered entities
---@field set table containing set functions of all registered entities
local M = {}

---register HA entity
---@param key string is data-payload attribute name
---@param specType string is one of HA NodeMCU-Device supported entity types
---@param spec table|function is returning HA NodeMCU-Device payload (entity specification)
---@param data table|function is returning HA NodeMCU-Device payload (entity data)
---@param setFn function is fnc(changes) accepting content of {<key>: <content>} when HA sends update command
local function main(key, specType, spec, data, setFn)
  package.loaded[modname] = nil

  assert(type(setFn) == "function", string.format("expects setFn to be function for %s", key))
  local state = require("state")(modname, {})

  state.specTypes = state.specTypes or {}
  state.specTypes[specType] = state.specTypes[specType] or {}
  for i, v in pairs(state.specTypes[specType]) do
    if v.key == key then
      table.remove(state.specTypes[specType], i)
      break
    end
  end
  table.insert(state.specTypes[specType], spec)

  state.data = state.data or {}
  state.data[key] = data

  state.set = state.set or {}
  state.set[key] = setFn
end

return main
