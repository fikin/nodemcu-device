local modname = ...

---scan args and if there is a function, execute it with remainder of arguments
---@param ... unknown
---@return ... input arguments until with first function but its result instead
local function expandArgs(...)
  local t = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if type(v) == "function" then
      t[#t + 1] = v(select(i + 1, ...))
      break
    end
    if v == nil then v = "nil" end
    t[#t + 1] = v
  end
  return table.unpack(t)
end

---executes string.format on given txt and arguments
---@param txt string
---@param ... unknown
---@return string
local function formMsg(txt, ...)
  local tail
  local ok, subTxt = pcall(string.format, txt, expandArgs(...))
  if ok then
    return subTxt
  else
    return "ERR: format log string failed :" .. subTxt
  end
end

---form source:line of logging point
---@return string
local function getLineinfo()
  local info = debug.getinfo(5, "Sl")
  return info.short_src .. ":" .. info.currentline
end

---logs an entry for given log level
---@param lvl string
---@param txt string
---@param ... any
local function logEntry(lvl, txt, ...)
  local msg = formMsg(txt, ...)
  local src = getLineinfo()
  local ts = require("get-timestamp")()

  return ts, src, msg
end

---convert log level string to log level number
---@param lvl string
---@return integer
local function levelToNbr(lvl)
  if lvl == "DEBUG" then
    return 1
  elseif lvl == "INFO" then
    return 2
  elseif lvl == "ERROR" then
    return 3
  else
    return 4 -- AUDIT
  end
end

---logs the message
---@param logLevel string
---@param logFn logfunc
---@return logentryfunc
local function main(logLevel, logFn)
  package.loaded[modname] = nil

  local ll = levelToNbr(string.upper(logLevel))

  ---@type logentryfunc
  return function(lvl, txt, ...)
    if levelToNbr(lvl) >= ll then
      local ts, src, msg = logEntry(lvl, txt, ...)
      logFn(lvl, ts, src, msg)
    end
  end
end

return main
