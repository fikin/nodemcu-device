local modname = ...

---calls a timer (once) with given delay and function
---@param delay integer in ms
---@param fnc fun() to call
local function main(delay, fnc)
  package.loaded[modname] = nil

  local tmr = require("tmr")
  local t = tmr:create()
  t:register(
    delay,
    tmr.ALARM_SINGLE,
    function(T)
      fnc()
    end
  )
  if not t:start() then
    require("log").error("failed starting a timer")
  end
end

return main
