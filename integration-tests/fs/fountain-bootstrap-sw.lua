--[[
Garden fountain controller
]]

local fs = require("factory-settings")

local pwd = "pswd"

local adminUsr = "admin"
local adminPwd = pwd

-- minimal HomeAssistant modules and credentials
fs("web-ha2")
    :set("credentials.usr", adminUsr):set("credentials.pwd", adminPwd)
    :done()

-- configure new HASS web (for devices)
fs("http-srv")
    :set("webModules", {
      "web-ha2", -- "devices" HASS web handler
    })
    :done()

-- minimal set of modules on.
fs("init-seq")
    :set("bootsequence", {
      "bootstrap",
      "http-srv",
    })
    :done()

local devinfo = {
  manufacturer = "niki",
  name = "Garden fountain",
  model = "nodemcu device",
}

local pump = {
  name = "pump",
  type = "switch-gpio",
  internal = false,
  spec = {
    name = "pump",
  },
  settings = {
    -- pin 0 is normally HIGH i.e. inverted/set to on
    -- used relay is also with normally HIGH input
    pin = 0,
    inverted = true,
    set_float = false,
    is_on = false,
  },
}

local leds = {
  name = "leds",
  type = "switch-gpio",
  internal = false,
  spec = {
    name = "leds",
  },
  settings = {
    -- pin 1 is normally HIGH i.e. inverted/set to off
    -- used relay is also with normally LOW input
    pin = 1,
    inverted = true,
    set_float = false,
    is_on = false,
  },
}

local water_level = {
  name = "water_level",
  type = "sensor-gpio",
  internal = false,
  spec = {
    name = "water level",
  },
  settings = {
    pin = 5,
    inverted = false,
    set_float = false,
    debounceMs = 300,
  },
}

local pump_control = {
  name = "pump_control",
  type = "switch-func",
  internal = false,
  spec = {
    name = "pump auto control",
  },
  settings = {
    funcname = "fnc-gated-switch",
    scheduleMs = 300,
    sensorId = "water_level",
    switchId = "pump",
    is_on = true,
  },
}

local df = require("device-factory")
df({
  info = devinfo,
  devices = {
    pump,
    water_level,
    leds,
    pump_control,
  },
})

-- restart at the end since the boot sequence is modified.
node.restart()
