--[[
    Logs log entries to a file.
]]
local modname = ...

---@class logfile_cfg
---@field outfile string
---@field logrotate integer

local file = require("file")

---@type logfile_cfg
local cfg = require("device-settings")(modname)

---removes the log file if exceeds logrotate file size
local function logrotate()
  local fp = file.stat(cfg.outfile)
  if fp and fp.size > cfg.logrotate then
    file.remove(cfg.outfile)
  end
end

---appends tstr to file
---@param str string
local function logappend(str)
  local fp = file.open(cfg.outfile, "a+")
  if fp then
    fp:writeline(str)
    fp:close()
  end
end

---writes the message to file
---@param logLevel string
---@param ts string
---@param src string
---@param msg string
local function writeEntry(logLevel, ts, src, msg)
  local str = string.format(
    "[%-6s%s] %s: %s",
    logLevel,
    ts,
    src,
    msg
  )

  logrotate()
  logappend(str)
  print(str)
end

local function main()
  package.loaded[modname] = nil

  ---@type logfunc
  return function(syslogLevel, ts, src, msg)
    writeEntry(syslogLevel, ts, src, msg)
  end
end

return main
