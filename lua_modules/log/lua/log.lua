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
      Update device settings.
      Updating the settings require log module reload.

  Depends on: rtctime, file, sjson, state
]]
local modname = ...

---object representing logger state settings
---@class logger_cfg
---@field level string
---@field logmodule string logging module name, providing logfunc to use

---a backend logging function
---@alias logfunc fun(syslogLevel:string,ts:string,src:string,msg:string):nil

---a function to process a log entry
---@alias logentryfunc fun(level:string, msg:string, ...:any)

---@type logger_cfg
local cfg = require("device-settings")(modname)
local logfn = require(cfg.logmodule)()
local logEntry = require("logentry")(cfg.level, logfn)

---logger object
---@class logger
local M = {}

---debug message
---@param format  string
---@param ... unknown
M.debug = function(format, ...) logEntry("DEBUG", format, ...); end
---info message
---@param format  string
---@param ... unknown
M.info = function(format, ...) logEntry("INFO", format, ...); end
---error message
---@param format  string
---@param ... unknown
M.error = function(format, ...) logEntry("ERROR", format, ...); end
---audit message
---@param format  string
---@param ... unknown
M.audit = function(format, ...) logEntry("AUDIT", format, ...); end

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

return M
