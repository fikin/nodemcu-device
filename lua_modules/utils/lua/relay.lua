local modname = ...

---relay configuration
---@class relay_cfg
---@field pin number
---@field inverted boolean|nil
---@field set_float boolean|nil

---relay read/write function
---@alias relay_fnc fun(set_to_on:boolean|nil):boolean

local log = require("log")
local gpio = require("gpio")

---initialize gpio pin to output
---@param cfg relay_cfg
local function init(cfg)
  log.debug("initializing gpio output : %s", log.json(cfg))
  gpio.mode(cfg.pin, gpio.OUTPUT, cfg.set_float and gpio.FLOAT or gpio.PULLUP)
end

---set pin if value defined and different from current gpio
---@param cfg relay_cfg
---@param set_to_on boolean|nil
local function set_if_defined(cfg, set_to_on)
  if set_to_on ~= nil then
    local val = set_to_on and gpio.HIGH or gpio.LOW
    val = cfg.inverted and not val or val
    if val ~= gpio.read(cfg.pin) then
      log.debug("gpio pin:%d : set to %d", cfg.pin, val)
      gpio.write(cfg.pin, val)
    end
  end
end

---wraps relay config into read/write function
---@param cfg relay_cfg
---@param perform_init boolean|nil initialiuze pin, call this only once at boot time
---@return relay_fnc
local function main(cfg, perform_init)
  package.loaded[modname] = nil

  if perform_init then
    init(cfg)
  end

  return function(set_to_on)
    set_if_defined(cfg, set_to_on)
    local val = gpio.read(cfg.pin) == 1
    return cfg.inverted and not val or val
  end
end

return main
