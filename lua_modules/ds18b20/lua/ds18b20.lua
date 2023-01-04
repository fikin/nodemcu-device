--------------------------------------------------------------------------------
-- DS18B20 one wire module for NODEMCU
-- NODEMCU TEAM
-- LICENCE: http://opensource.org/licenses/MIT
-- @voborsky, @devsaurus, TerryE  26 Mar 2017
--------------------------------------------------------------------------------
local modname = ...

local ow, node, tmr = require("ow"), require("node"), require("tmr")

-- Used modules and functions
local type, tostring, pcall, ipairs = type, tostring, pcall, ipairs
-- Local functions
local ow_setup,
ow_search,
ow_select,
ow_read,
ow_read_bytes,
ow_write,
ow_crc8,
ow_reset,
ow_reset_search,
ow_skip,
ow_depower =
ow.setup,
    ow.search,
    ow.select,
    ow.read,
    ow.read_bytes,
    ow.write,
    ow.crc8,
    ow.reset,
    ow.reset_search,
    ow.skip,
    ow.depower

local node_task_post, node_task_LOW_PRIORITY = node.task.post, node.task.LOW_PRIORITY
local string_char = string.char
local tmr_create, tmr_ALARM_SINGLE = tmr.create, tmr.ALARM_SINGLE
local table_sort = table.sort
local math_floor = math.floor

---forward declaration
---@type function
local conversion

local DS18B20FAMILY = 0x28
local DS1920FAMILY = 0x10 -- and DS18S20 series
local CONVERT_T = 0x44
local READ_SCRATCHPAD = 0xBE
local READ_POWERSUPPLY = 0xB4
local MODE = 1

---pin ow is connected to
---@type integer
local pin = 3
---callback upon successful reading
---@type function
local cb = nil
---meassurement unit to report temperature off
---@type string
local unit = nil

---@type integer[]
local status = {}

local debugPrint = require("log").debug

--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------

---converts ow sensor addr to string representation
---@param addr any
---@return string
local function to_string(addr)
  if type(addr) == "string" and #addr == 8 then
    return ("%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X "):format(addr:byte(1, 8))
  else
    return tostring(addr)
  end
end

---read temperature
---@param self ds18b20*
local function readout(self)
  local next = false
  local sens = self.sens
  local temp = self.temp
  for i, s in ipairs(sens) do
    if status[i] == 1 then
      ow_reset(pin)
      local addr = s:sub(1, 8)
      ow_select(pin, addr) -- select the  sensor
      ow_write(pin, READ_SCRATCHPAD, MODE)
      local data = ow_read_bytes(pin, 9)

      local t = (data:byte(1) + data:byte(2) * 256)
      -- t is actually signed so process the sign bit and adjust for fractional bits
      -- the DS18B20 family has 4 fractional bits and the DS18S20s, 1 fractional bit
      t = ((t <= 32767) and t or t - 65536) * ((addr:byte(1) == DS18B20FAMILY) and 625 or 5000)
      local crc, b9 = ow_crc8(string.sub(data, 1, 8)), data:byte(9)

      t = t / 10000
      if math_floor(t) ~= 85 then
        if unit == "F" then
          t = t * 18 / 10 + 32
        elseif unit == "K" then
          t = t + 27315 / 100
        end
        debugPrint("%s %d %d %d", to_string(addr), t, crc, b9)
        if crc == b9 then
          temp[addr] = t
        end
        status[i] = 2
      end
    end
    next = next or status[i] == 0
  end
  if next then
    node_task_post(
      node_task_LOW_PRIORITY,
      function()
        return conversion(self)
      end
    )
  else
    --sens = {}
    if cb then
      node_task_post(
        node_task_LOW_PRIORITY,
        function()
          return cb(temp)
        end
      )
    end
  end
end

---start ow reading
---@param self ds18b20*
conversion = (function(self)
  local sens = self.sens
  local powered_only = true
  for _, s in ipairs(sens) do
    powered_only = powered_only and s:byte(9) ~= 1
  end
  if powered_only then
    debugPrint("starting conversion: all sensors")
    ow_reset(pin)
    ow_skip(pin) -- skip ROM selection, talk to all sensors
    ow_write(pin, CONVERT_T, MODE) -- and start conversion
    for i, _ in ipairs(sens) do
      status[i] = 1
    end
  else
    local started = false
    for i, s in ipairs(sens) do
      if status[i] == 0 then
        local addr, parasite = s:sub(1, 8), s:byte(9) == 1
        if parasite and started then
          break
        end -- do not start concurrent conversion of powered and parasite
        debugPrint("starting conversion: %s %s", to_string(addr), parasite and "parasite" or "")
        ow_reset(pin)
        ow_select(pin, addr) -- select the sensor
        ow_write(pin, CONVERT_T, MODE) -- and start conversion
        status[i] = 1
        if parasite then
          break
        end -- parasite sensor blocks bus during conversion
        started = true
      end
    end
  end
  tmr_create():alarm(
    750,
    tmr_ALARM_SINGLE,
    function()
      return readout(self)
    end
  )
end)

---search for all ow devices and read temperature
---@param self ds18b20*
---@param lcb function to call after readout
---@param lpin integer is ow pin
local function _search(self, lcb, lpin)
  self.temp = {}
  self.sens = {}
  status = {}
  local sens = self.sens
  pin = lpin or pin

  local addr
  ow_setup(pin)
  if #sens == 0 then
    ow_reset_search(pin)
    -- ow_target_search(pin,0x28)
    -- search the first device
    addr = ow_search(pin)
  else
    for i, _ in ipairs(sens) do
      status[i] = 0
    end
  end
  local function cycle()
    if addr then
      local crc = ow_crc8(addr:sub(1, 7))
      if (crc == addr:byte(8)) and ((addr:byte(1) == DS1920FAMILY) or (addr:byte(1) == DS18B20FAMILY)) then
        ow_reset(pin)
        ow_select(pin, addr)
        ow_write(pin, READ_POWERSUPPLY, MODE)
        local parasite = (ow_read(pin) == 0 and 1 or 0)
        sens[#sens + 1] = addr .. string_char(parasite)
        status[#sens] = 0
        debugPrint("contact: %s %s", to_string(addr), parasite == 1 and "parasite" or "")
      end
      addr = ow_search(pin)
      node_task_post(node_task_LOW_PRIORITY, cycle)
    else
      ow_depower(pin)
      -- place powered sensors first
      table_sort(
        sens,
        function(a, b)
          return a:byte(9) < b:byte(9)
        end
      ) -- parasite
      if lcb then
        node_task_post(node_task_LOW_PRIORITY, lcb)
      end
    end
  end

  cycle()
end

---Set module name as parameter of require and return module table
---@class ds18b20*
local M = {
  sens = {},
  temp = {},
  C = "C",
  F = "F",
  K = "K"
}

---reads sensors and their temps
---@param self ds18b20* instance
---@param lcb function to call when reading is finished
---@param lpin integer is ow pin
---@param lunit string is meassurement unit
M.read_temp = function(self, lcb, lpin, lunit)
  cb, unit = lcb, lunit or unit
  _search(
    self,
    function()
      return conversion(self)
    end,
    lpin
  )
end

return M
