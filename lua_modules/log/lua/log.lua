--[[ 
  A logger.
  Logs entries and objects to console.

  Usage:
    local log = require("log")
    log.info(msg, ...)
    log.debug(msg, ...)
    log.error(msg, ...)
    log.audit(msg, ...)

  Logging:
    It accepts varrying number of arguments.
    It logs all arguments using "tostring" function.

    It offers a convenience method to convert table to json:
      log.json(table)
        A convenience method to call sjson to serialize the table.
        One can use it as logging argument as well as on its own.
    
    Lazy arguments evaluation:
      This is optimization for running text formatting or json conversion
        when logging level is not on.
      Mainly this is relevant to "debug", assuming "info" is on by default.
      Logger recognizes functions as arguments and calls them if logging level is on.
        "log.<>(..., function, arguments)" is equivalent to "log.<>(function(arguments))".
      For example one should code : log.debug("some object", log.json, object)
        instead of log.debug("some object", log.json(object)) as in first form
        log.json will gets executed only of logging level is "debug".
      Note, only first logging argument of type function is recoginized, 
        all consequent arguments are assumed to be function's arguments.

  Options:
    require("state").log.usecolor = true -- default false
      Useful if one is using it over "telnet" with real terminal, the messages will be colored.

    require("state").log.outfile = "syslog" -- default nil
      Saves all messages to given file.
      Note the file is opened and closed each time a message is emmitted, this is slow !

    require("state").log.logrotate = 512 -- default 1024
      File size threshold before the file will be removed.
      This is protection against ever growing log files.
      Old logs are simply removed.

    require("state").log.level = "debug" -- default "info"
      Logging level.

  Depends on: rtctime, file, sjson, state

  Logging settings at RTE are maintained in:
    require("state")("log")

  Logging settings can be present in "device_settings" and 
  one has to use bootprotect to assign these to RTE state:
      require("state").log = require("device-settings").log
]]
local modname = ...

---object representing logger state settings
---@class logger_state
---@field usecolor boolean
---@field level integer
---@field outfile string
---@field logrotate integer

---returns timestamp from rtctime
---@return string
local function getTimestamp()
  local rtctime = require("rtctime")
  local tm = rtctime.epoch2cal(rtctime.get().sec)
  return string.format(
    "%04d/%02d/%02d %02d:%02d:%02d",
    tm.year,
    tm.mon,
    tm.day,
    tm.hour,
    tm.min,
    tm.sec
  )
end

---formats arguments into logging string
---@param ... unknown
---@return string
local function toStrArgs(...)
  local t = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if type(v) == "function" then
      t[#t + 1] = tostring(v(select(i + 1, ...)))
      break
    end
    t[#t + 1] = tostring(v)
  end
  return table.concat(t, " ")
end

---saves the log message to a file
---@param state logger_state
---@param str string
local function logToFile(state, str)
  local file = require("file")
  local fp = file.stat(state.outfile)
  if fp and fp.size > state.logrotate then
    file.remove(state.outfile)
  end
  fp = file.open(state.outfile, "a+")
  if fp then
    fp:writeline(str)
    fp:close()
  end
end

---@class logger_level
---@field p integer log level as integer
---@field n string log level as text
---@field c string log level color codes

---logger levels
---@type table<string,logger_level>
local levels = {
  ["debug"] = { p = 1, n = "DEBUG", c = "\27[36m" },
  ["info"] = { p = 2, n = "INFO", c = "\27[32m" },
  ["error"] = { p = 3, n = "ERROR", c = "\27[31m" },
  ["audit"] = { p = 4, n = "AUDIT", c = "\27[33m" }
}

---returns logger RTE state
---@return logger_state
local function readState()
  local state = require("state")(modname)
  if not state.level then
    -- lazy creating the initial table
    state = { level = "info", usecolor = false, outfile = nil, logrotate = 512 }
    require("state")()[modname] = state
  end
  return state
end

---logs an entry for given log level
---@param lvl logger_level
---@param ... unknown
local function logEntry(lvl, ...)
  local state = readState()

  -- Return early if we're below the log level
  if lvl.p < levels[state.level].p then
    return
  end

  local info = debug.getinfo(3, "Sl")
  local lineinfo = info.short_src .. ":" .. info.currentline
  local str =
  string.format(
    "%s[%-6s%s]%s %s: %s",
    state.usecolor and lvl.c or "",
    lvl.n,
    getTimestamp(),
    state.usecolor and "\27[0m" or "",
    lineinfo,
    toStrArgs(...)
  )

  -- Output to console
  print(str)

  -- Output to log file
  if state.outfile then
    logToFile(state, str)
  end
end

---logger object
---@class logger
local M = {}

---debug message
---@param ... unknown
M.debug = function(...) logEntry(levels.debug, ...); end
---info message
---@param ... unknown
M.info = function(...) logEntry(levels.info, ...); end
---error message
---@param ... unknown
M.error = function(...) logEntry(levels.error, ...); end
---audit message
---@param ... unknown
M.audit = function(...) logEntry(levels.audit, ...); end

---print to stdout given data
---@param t any
M.print = function(t)
  if type(t) == "table" then
    for k, v in pairs(t) do
      print(k, v)
    end
  else
    print(t)
  end
end

---returns keys and values in given table as text array
---@param t table
---@return table
M.tbl = function(t)
  local ret = {}
  for k, v in pairs(t) do
    table.insert(ret, string.format("%s = %s", k, v))
  end
  return ret
end

---converts value as json text
---@param v any
---@return string
M.json = function(v)
  if type(v) == "table" then
    local sjson = require("sjson")
    local ok, ret = pcall(sjson.encode, v)
    if not ok then
      ret = sjson.encode(M.tbl(v))
    end
    ---@cast ret string
    return ret
  end
  return tostring(v)
end

---returns timestamp function
---@return string
M.ts = getTimestamp

return M
