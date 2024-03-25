local modname = ...

---@alias rctstate_rw fun(indx:integer|nil,val:number|nil):boolean,number

local crc8 = require("crc8")
local bit = require("bit")
local rtcmem = require("rtcmem")
local tokenize32 = require("tokenize32")

local quartet1 = 10

---@param mName string module name
---@param min integer
---@param max integer
---@return fun(val:integer|nil):integer
local function assertRange(mName, min, max)
  local msg = mName .. " module expected " .. tonumber(min) .. "<=indx<=" .. tonumber(max) .. " but found "
  return function(val)
    assert(val ~= nil, msg .. "nil")
    assert(min <= val and val <= max, msg .. tostring(val))
    return val
  end
end

---@param mName string
---@return fun(val:integer|nil):integer
local function assertNil(mName, def)
  local msg = mName .. " module expects nil index but got "
  return function(val)
    assert(val == nil, msg .. tostring(val))
    return def
  end
end

---combine 4 bytes into single 32bits value
---@param arr number[]
---@return number
local function arrTo32(arr)
  local val = arr[1]
  for i = 2, 4 do
    val = bit.bor(bit.lshift(val, 8), arr[i])
  end
  return val
end

---@param base integer
---@return boolean
---@return number[] values 1..3 32bits words
---@return number[] crcs 1..3 bytes of crc8
local function readQuartet(base)
  local vals = { rtcmem.read32(base, 4) }
  local crcs = { tokenize32(vals[4]) }
  if crcs[4] ~= crc8({ crcs[1], crcs[2], crcs[3] }) then
    return false, { 0, 0, 0 }, { 0, 0, 0 }
  end
  for i = 1, 3 do
    if crcs[i] ~= crc8({ tokenize32(vals[i]) }) then
      return false, { 0, 0, 0 }, { 0, 0, 0 }
    end
  end
  return true, { vals[1], vals[2], vals[3] }, { crcs[1], crcs[2], crcs[3] }
end

---@param quarted integer
---@param vals number[] 1..3 words
---@param crcs number[] 1..3 crc8
---@param indx integer to update from vals
---@param val number actual value
local function updateQuarted(quarted, vals, crcs, indx, val)
  vals[indx] = val
  crcs[indx] = crc8({ tokenize32(val) })
  local arr = { crcs[1], crcs[2], crcs[3] }
  table.insert(arr, crc8(arr))
  rtcmem.write32(quarted, vals[1], vals[2], vals[3], arrTo32(arr))
end

---@param quarted integer
---@param quartedIndx integer
---@param assertFn fun(val:integer|nil):integer
---@return rctstate_rw
local function rw32(quarted, quartedIndx, assertFn)
  local ok, vals, crcs = readQuartet(quarted)
  return function(indx, val)
    indx = quartedIndx + assertFn(indx)
    if val then
      updateQuarted(quarted, vals, crcs, indx, val)
      ok = true
    end
    return ok, vals[indx]
  end
end

---@param quarted integer
---@param quartedIndx integer
---@param assertFn fun(val:integer|nil):integer
---@return rctstate_rw
local function rw8(quarted, quartedIndx, assertFn)
  local ok, vals, crcs = readQuartet(quarted)
  local bytes = { tokenize32(vals[quartedIndx]) }
  return function(indx, val)
    indx = assertFn(indx)
    if val then
      bytes[indx] = bit.band(val, 0xFF)
      updateQuarted(quarted, vals, crcs, quartedIndx, arrTo32(bytes))
      ok = true
    end
    return ok, bytes[indx]
  end
end

---read/write state in RTC memory
---module : ("time", nil) supports single 32bits value
---module : {"bootprotect", 1..4} supports 4 8bit values
---module : {"temperature", 1..4} supports 4 8bit values
---module : {"humidity", 1..4} supports 4 8bit values
---@param modulename string module specific r/w function
---@return rctstate_rw
local function main(modulename)
  package.loaded[modname] = nil

  if modulename == "time" then
    return rw32(quartet1, 1, assertNil("time", 0))
  elseif modulename == "bootprotect" then
    return rw8(quartet1, 2, assertRange("bootprotect", 1, 4))
  elseif modulename == "temperature" then
    return rw8(quartet1, 3, assertRange("temperature", 1, 4))
  elseif modulename == "humidity" then
    return rw8(quartet1 + 4, 1, assertRange("humidity", 1, 4))
  elseif modulename == "telnet" then
    return rw32(quartet1 + 4, 2, assertNil("telnet", 0))
  elseif modulename == "sntp-sync" then
    return rw8(quartet1 + 4, 3, assertNil("sntp-sync", 0))
  else
    error("unsupported module name " .. modulename)
  end
end

return main
