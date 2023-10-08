--[[
    Logs log entries to stdout.
]]
local modname = ...

---@class logstdout_cfg
---@field usecolor boolean

---return color codes for level
---@param lvl string all-caps log level
---@return string
local function getColor(lvl)
  if lvl == "INFO" then
    return "\27[32m"
  elseif lvl == "error" then
    return "\27[31m"
  elseif lvl == "DEBUG" then
    return "\27[36m"
  else -- AUDIT
    return "\27[33m"
  end
end

---prints the message to stdout
---@param usecolor boolean
---@param logLevel string
---@param ts string
---@param src string
---@param msg string
local function printEntry(usecolor, logLevel, ts, src, msg)
  local clr = usecolor and getColor(logLevel) or nil
  local str = string.format(
    "%s[%-6s%s]%s %s: %s",
    clr or "",
    logLevel,
    ts,
    clr and "\27[0m" or "",
    src,
    msg
  )

  print(str)
end

local function main()
  package.loaded[modname] = nil

  ---@type logstdout_cfg
  local ds = require("device-settings")(modname)

  ---@type logfunc
  return function(syslogLevel, ts, src, msg)
    printEntry(ds.usecolor, syslogLevel, ts, src, msg)
  end
end

return main
