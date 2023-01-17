--[[
  Runs sequence of functions, one after another.
  
  In case of error, it offers a time delay and then runs it again.

  In case of device reboot, it runs same sequence of functions but pauses
  before running same function, which caused the reboot.

  User is able to abort sequence execution by issuing command:
    require("bootprotect").stop()

  This module is meant to control device boot sequence and in case of errors
  offer some graceful way to intervine.

  Usage:
    local b = require("bootprotect")
    b.fnc("my fnc1", function() print(1) end)
    b.fnc("my fnc2", function() print(2) end)
    b.start()

  One can configure:
    - an on-error function being called each time when new delay is being triggered
      Note: add a function to the end of the boot sequence to clear all error indications
        which the error function might have raised, like blinking leds or etc.
        Reaching the end of the sequence would mean there are no more errors encountered.
      example: b.errFnc(function() print("do something when function fails") end)

    - configure time delay before calling a failed function, by default it is 30sec
      example: b.delaySec(10)

  Credits:
    This module was inspired by but it is not the same as
    https://github.com/HHHartmann/nodemcu-LFS-base/blob/master/LFS/bootprotect.lua
]]
local modname = ...

---repesent boot sequence manager
---@class bootprotect*
local M = {}

---rtcmem containing number of failing function, survives across restarts
local rtcSlot = 16

---list of functions to run
---@type function[]
local funcs = {}

--- delay duration before starting a failing function
---@type integer
local delaySec = 30

---delay timer
---@type table|nil
local tm

---function to run on error
---@type function|nil
local onErrFnc = nil

local log, rtcmem, tmr = require("log"), require("rtcmem"), require("tmr")
local rtcW, rtcR = rtcmem.write32, rtcmem.read32

---returns the step number (boot sequence wise) of last step before reboot occurs
---@return integer the number or 0 if no error has occured previous boot
local function getLastFailedNbr()
  local nbr = rtcR(rtcSlot) -- survived from previous reboot env
  local rawcode, reason = require("node").bootreason()
  log.debug("rtcmem slot=%d  value=%d boot rawcode=%d boot reason=%d", rtcSlot, nbr, rawcode, reason)
  if nbr > 0 and nbr < 100 and rawcode == 2 and reason == 4 then
    return nbr
  end
  return 0
end

local lastFailedNbr = getLastFailedNbr()

---called at end of boot sequence, purpose is to clear all memory use
local function endOfSeq()
  log.info("boot sequence is over")
  funcs = {}
  onErrFnc = nil
  tm = nil
  M = {}
  rtcW(rtcSlot, 0)
  package.loaded[modname] = nil --gc at the end
  collectgarbage()
  collectgarbage()
end

---runs the function at step nbr
---@param nbr integer step to run
---@return boolean true if executed ok, otherwise false
---@return any is the result of the function or error if boolean is false
local function runFncOk(nbr)
  local msg = funcs[nbr][1]
  local fnc = funcs[nbr][2]
  log.info("(%d) (heap: %d) %s", nbr, require("node").heap(), msg)
  local ok, err = pcall(fnc)
  collectgarbage()
  collectgarbage()
  log.info("(%d) heap: %d", nbr, require("node").heap())
  return ok, err
end

---forward declarations
---@type fun(nbr: integer)
local run
---forward declarations
---@type fun(nbr: integer)
local doRun
---forward declarations
---@type fun(nbr: integer)
local delayBeforeRun

---runs the step and:
---   in case of success, runs next step (tail recursion)
---   calls errFnc in case of failure and then
---   schedules are delayed execution of same step using delayBeforeRun
---@param nbr integer step to run
doRun = function(nbr)
  local ok, err = runFncOk(nbr)
  if ok then
    -- no-err, continue tail recursion
    run(nbr + 1)
  else
    -- on new failure, repeat via timer with delay
    log.error("function #%d failed: %s", nbr, err)
    if onErrFnc then onErrFnc(); end
    delayBeforeRun(nbr)
  end
end

---schedules a timer to run given step using doRun
---@param nbr integer step to run
delayBeforeRun = function(nbr)
  log.error("waiting for %d sec. before calling function (%d) : %s", delaySec, nbr, funcs[nbr][1])
  log.info('call `require("bootprotect").stop()` before that to interrupt the sequence.')
  local tmrFnc = function()
    tm = nil
    doRun(nbr)
  end
  tm = tmr.create()
  tm:alarm(delaySec * 1000, tmr.ALARM_SINGLE, tmrFnc)
end

---runs the step using doRun.
---it maintains track of the execution in rtcmem in case we have to track unexpected reboots.
---it garbage collects resources if sequence is over.
---@param nbr integer is step to run
run = function(nbr)
  if nbr > #funcs then
    -- end of recursion
    endOfSeq()
  else
    rtcW(rtcSlot, nbr) -- store current nbr in case we fail unexpectedly
    if lastFailedNbr == nbr then
      -- previous boot failed, continue via timer with delay
      log.error("function failed previous boot (%d): %s", nbr, funcs[nbr][1])
      delayBeforeRun(nbr)
    else
      doRun(nbr)
    end
  end
end

---register function to be started
---@param name string is boot step name
---@param fnc function is the function to call
---@return bootprotect*
M.fnc = function(name, fnc)
  table.insert(funcs, { name, fnc })
  return M
end

---register function to be started (shortcut for "require(modName)()")
---@param name string is boot step name
---@param modName string is module name to require
---@return bootprotect*
M.require = function(name, modName)
  local fn = function()
    require(modName)()
  end
  return M.fnc(name, fn)
end

---function to be called in case some error occured
---@param fnc function to call in case of error
---@return bootprotect*
M.errFnc = function(fnc)
  onErrFnc = fnc
  return M
end

---how much time to wait before repeating a failed function
---default defined in device settings
---@param delay integer in ms
---@return bootprotect*
M.delaySec = function(delay)
  delaySec = delay
  return M
end

---start execution of the sequence
M.start = function()
  log.info("starting up boot sequence")
  run(1)
end

---stop execution the sequence
---this can be called manually during troubleshooting times
M.stop = function()
  log.audit("user interrupted boot sequence")
  if tm then
    tm:stop()
  end
end

return M
