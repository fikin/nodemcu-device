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

local M = {}

local rtcSlot = 16 -- rtcmem containing number of failing function, survives across restarts

local funcs = {} -- list of functions to run
local delaySec = 30 -- delay duration before starting a failing function
local tm  -- delay timer
local onErrFnc = function(err) -- function to run on error
end

local log, rtcmem, tmr = require("log"), require("rtcmem"), require("tmr")
local rtcW, rtcR = rtcmem.write32, rtcmem.read32

local function getLastFailedNbr()
  local nbr = rtcR(rtcSlot) -- survived from previous reboot env
  local rawcode, reason = node.bootreason()
  log.debug("rtcmem", rtcSlot, "=", nbr, "boot rawcode=", rawcode, "boot reason=", reason)
  if nbr > 0 and nbr < 100 and rawcode == 2 and reason == 4 then
    return nbr
  end
  return 0
end

local lastFailedNbr = getLastFailedNbr()

local function endOfSeq()
  log.info("boot sequence is over")
  funcs = nil
  onErrFnc = nil
  tm = nil
  M = nil
  rtcW(rtcSlot, 0)
  package.loaded[modname] = nil --gc at the end
  collectgarbage()
  collectgarbage()
end

local function runFncOk(nbr)
  local msg = funcs[nbr][1]
  local fnc = funcs[nbr][2]
  log.info("calling function (%d) : %s" % {nbr, msg})
  local ok, err = pcall(fnc)
  collectgarbage()
  collectgarbage()
  return ok, err
end

local run, doRun, delayBeforeRun

doRun = function(nbr)
  local ok, err = runFncOk(nbr)
  if ok then
    -- no-err, continue tail recursion
    run(nbr + 1)
  else
    -- on new failure, repeat via timer with delay
    log.error("function failed (%d): %s" % {nbr, err})
    onErrFnc()
    delayBeforeRun(nbr)
  end
end

delayBeforeRun = function(nbr)
  log.error("waiting for %d sec. before calling function (%d) : %s" % {delaySec, nbr, funcs[nbr][1]})
  log.info('call `require("bootprotect").stop()` before that to interrupt the sequence.')
  local tmrFnc = function()
    tm = nil
    doRun(nbr)
  end
  tm = tmr.create()
  tm:alarm(delaySec * 1000, tmr.ALARM_SINGLE, tmrFnc)
end

run = function(nbr)
  if nbr > #funcs then
    -- end of recursion
    endOfSeq()
  else
    rtcW(rtcSlot, nbr) -- store current nbr in case we fail unexpectedly
    if lastFailedNbr == nbr then
      -- previous boot failed, continue via timer with delay
      log.error("function failed previous boot (%d): %s" % {nbr, funcs[nbr][1]})
      delayBeforeRun(nbr)
    else
      doRun(nbr)
    end
  end
end

M.fnc = function(name, fnc)
  table.insert(funcs, {name, fnc})
  return M
end

M.errFnc = function(fnc)
  onErrFnc = fnc
  return M
end

M.delaySec = function(delay)
  delaySec = delay
  return M
end

M.start = function()
  log.info("starting up boot sequence")
  run(1)
end

M.stop = function()
  log.audit("user interrupted boot sequence")
  if tm then
    tm:stop()
  end
end

return M
