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
    require("wifi-event")(modname,eventType,fnc)
    
    where:
      - modname is anything you like, for example lua module name
      - eventType is wifi.eventmon event type
      - fnc is the callback

  Uniqueness of functions internally is maintained as "<modname>_<eventType>".

  Examples:
    require("wifi-event")("myApp1",wifi.eventmon.STA_GOT_IP, function(T) doSomething() end)
    ...
    require("wifi-event")("myApp2",wifi.eventmon.STA_GOT_IP, function(T) doSomethingElse() end)
    ...
    require("wifi-start-sta")() -- starts wifi connection process
    -- at this moment all functions will be called when GOT_IP is received.
]]
local modname = ...

---wifi event callback signature
---@alias wifi_cb_fn fun(T: table)

---signature if wifi_event function
---@alias wifi_event fun(moduelId: string, eventType: integer, fnc: wifi_cb_fn)

local wifi = require("wifi")

local state = require("state")(modname)

---determine table's length i.e. count of keys
---@param T table
---@return integer
local function tablelength(T)
  local count = 0
  for _ in pairs(T) do
    count = count + 1
  end
  return count
end

---a wifi event callabck, calling all registered for that event functions
---@param eT string
---@param eventType integer
---@param T table the payload as coming from wifi.event
local function cbFnc(eT, eventType, T)
  for k, v in pairs(state[eT]) do
    local ok, err = pcall(v, T)
    if not ok then
      require("log").error("failure inside %s: %s", k, err)
    end
    collectgarbage()
  end
end

---create new callback wrapper for given function and event
---@param eT string
---@param eventType integer
---@return wifi_cb_fn
local function newCbFnc(eT, eventType)
  return function(T)
    cbFnc(eT, eventType, T)
  end
end

---register a new event callback function
---@param eT string
---@param moduelId string
---@param eventType integer
---@param fnc wifi_cb_fn
local function addCb(eT, moduelId, eventType, fnc)
  state[eT] = state[eT] or {}
  state[eT][moduelId] = fnc
  if tablelength(state[eT]) == 1 then
    wifi.eventmon.register(eventType, newCbFnc(eT, eventType))
  end
end

---removes a registered callback
---@param eT string
---@param moduelId string
---@param eventType integer
local function removeCb(eT, moduelId, eventType)
  state[eT][moduelId] = nil
  if tablelength(state[eT]) == 0 then
    wifi.eventmon.unregister(eventType)
    state[eT] = nil
  end
end

---register fnc-callback to wifi.eventmon eventType
---moduelId_eventType is the internal unique ID to identify the function
---@param moduelId string
---@param eventType integer
---@param fnc wifi_cb_fn
---@return wifi_event
local function onFnc(moduelId, eventType, fnc)
  package.loaded[modname] = nil

  local eT = require("wifi-event-type")(eventType)
  if fnc then
    addCb(eT, moduelId, eventType, fnc)
  else
    removeCb(eT, moduelId, eventType)
  end
  return onFnc
end

return onFnc
