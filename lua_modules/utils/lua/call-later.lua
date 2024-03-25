local modname = ...

---calls a timer (once) with given delay and function
---@param delay integer in ms
---@param fnc fun() to call
local function main(delay, fnc)
  package.loaded[modname] = nil

  local tmr = require("tmr")
  if not tmr:create():alarm(
        delay,
        tmr.ALARM_SINGLE,
        fnc
      ) then
    require("log").error("failed starting a timer")
  end
end

return main
