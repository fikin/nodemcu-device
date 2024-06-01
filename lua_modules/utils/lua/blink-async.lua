local modname = ...

---Blink built-in led 2 times/sec
---This is ASYNC function i.e. run under scheduler
---@param durationSec integer to keep blinking
---@param blinksPerSec integer
---@param stopFn fun():boolean if returns true, it aborts loop.
local function main(durationSec, blinksPerSec, stopFn)
  package.loaded[modname] = nil

  local delay = 1000 / (blinksPerSec * 2)
  local iters = durationSec * blinksPerSec * 2

  local gpio = require("gpio")
  gpio.mode(4, gpio.OUTPUT)
  local flg = 0
  for _ = 1, iters do
    if stopFn() then
      gpio.write(4, 0) -- leave it ON
      return           -- outer loop will exit the sequence
    end
    gpio.write(4, flg)
    flg = 1 - flg
    require("scheduler"):sleep(delay)
  end
  gpio.write(4, 1) -- OFF
end

return main
