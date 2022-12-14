--[[
  Manager of various HomeAssistant entities, registered with this device.

  Each entity is recognized by "key", which is accidentially is named
  after "{<key>: {...entity data...}}" inside data payload.
]]
local modname = ...

local M = {}

-- register HA entity
-- "key" is data-payload attribute name
-- "specType" is one of HA NodeMCU-Device supported entity types
-- "spec" is string or function returning HA NodeMCU-Device payload (entity specification)
-- "data" is string or function returning HA NodeMCU-Device payload (entity data)
-- "setFn" is function(data) accepting content of {<key>: <content>} when HA sends update command
local function main(key, specType, spec, data, setFn)
  package.loaded[modname] = nil

  if type(setFn) ~= "function" then
    error("expects setFn to be function for %s" % key)
  end

  local state = require("state")(modname, {})
  state.spec = state.spec or {}
  state.spec[key] = spec
  state.data = state.data or {}
  state.data[key] = data
  state.set = state.set or {}
  state.set[key] = setFn
end

return main
