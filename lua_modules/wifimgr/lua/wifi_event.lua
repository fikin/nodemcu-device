--[[
  Maintains unique list (set) of wifi.eventmon callback functions per event type.

  Use this module instead of wifi.eventmon directly.

  Since wifi.eventmon supports a single function per event type,
    this module is wrapping this and allows one to gradually define
    more callbacks for same event.

  Note:
    This module maintains table with all callbacks in RAM i.e. beware or memory consumption!
  Note:
    If you call wifi.eventmon.register on your own, 
    functions defined by this module will be ignored. 
  Note:
    Passing nil for function will release the function from the memory and callbacks list.

  Usage:
    require("wifi_event")(modname,eventType,fnc)
    
    where:
      - modname is anything you like, for example lua module name
      - eventType is wifi.eventmon event type
      - fnc is the callback

  Uniqueness of functions internally is maintained as "<modname>_<eventType>".

  Examples:
    require("wifi_event")("myApp1",wifi.eventmon.STA_GOT_IP, function(T) doSomething() end)
    ...
    require("wifi_event")("myApp2",wifi.eventmon.STA_GOT_IP, function(T) doSomethingElse() end)
    ...
    require("wifi_start_sta")() -- starts wifi connection process
    -- at this moment all functions will be called when GOT_IP is received.
]]
local modname = ...

local wifi = require("wifi")

local state = require("state")(modname)

local function tablelength(T)
  local count = 0
  for _ in pairs(T) do
    count = count + 1
  end
  return count
end

local function cbFnc(eT, eventType, T)
  for k, v in pairs(state[eT]) do
    local ok, err = pcall(v, T)
    if not ok then
      require("log").error("failure inside %s: %s" % {k, err})
    end
    collectgarbage()
  end
end

local function newCbFnc(eT, eventType)
  return function(T)
    cbFnc(eT, eventType, T)
  end
end

local function addCb(eT, moduelId, eventType, fnc)
  state[eT] = state[eT] or {}
  state[eT][moduelId] = fnc
  if tablelength(state[eT]) == 1 then
    wifi.eventmon.register(eventType, newCbFnc(eT, eventType))
  end
end

local function removeCb(eT, moduelId, eventType)
  state[eT][moduelId] = nil
  if tablelength(state[eT]) == 0 then
    wifi.eventmon.unregister(eventType)
    state[eT] = nil
  end
end

-- register fnc-callback to wifi.eventmon eventType
-- moduelId_eventType is the internal unique ID to identify the function
local function onFnc(moduelId, eventType, fnc)
  package.loaded[modname] = nil

  local eT = require("wifi_event_type")(eventType)
  if fnc then
    addCb(eT, moduelId, eventType, fnc)
  else
    removeCb(eT, moduelId, eventType)
  end
  return onFnc
end

return onFnc
