local modname = ...

---@param last integer holds last pulse tmr.now value
---@return tmr_fn
local function schedulerPulse(last)
  return function(_)
    local n = require("tmr").now()
    local deltaTicks = math.floor(math.abs(n - last) / 1000)
    last = n
    require("scheduler"):pulse(deltaTicks)
  end
end

---@param schedulerIntervalMs integer scheduler pulse interface
local function startScheduler(schedulerIntervalMs)
  require("log").info("starting scheduler with frequewnce %d ms", schedulerIntervalMs)
  local tmr = require("tmr")
  tmr.create():alarm(schedulerIntervalMs, tmr.ALARM_AUTO, schedulerPulse(tmr.now()))
end

---@param schedulerIntervalMs integer scheduler pulse interface
local function main(schedulerIntervalMs)
  package.loaded[modname] = nil

  startScheduler(schedulerIntervalMs)
end

return main
