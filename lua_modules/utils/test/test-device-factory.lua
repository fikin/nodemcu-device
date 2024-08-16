local lu = require("luaunit")
local nodemcu = require("nodemcu")
local file = require("file")
local gpio = require("gpio")

local function removeFiles(pattern)
    for name, _ in pairs(file.list(pattern)) do
        file.remove(name)
    end
end

local function removeDevFiles()
    removeFiles("^dev%-.*")
    removeFiles("^ds%-dev%-.*")
end

local devinfo = {
    manufacturer = "my manufacturer",
    name = "my device name",
    model = "my model",
    swVersion = "my sw version",
    hwVersion = "my hw version",
}

local door_sensor = {
    name = "door_sensor",
    type = "sensor-gpio",
    internal = false,
    spec = {
        name = "my door sensor",
    },
    settings = {
        pin = 1,
        inverted = false,
        set_float = false,
        debounceMs = 0, -- no debounce for now
    },
}

local water_sensor = {
    name = "water_sensor",
    type = "sensor-gpio",
    internal = true,
    spec = {
        name = "my bouncing sensor",
    },
    settings = {
        pin = 3,
        inverted = true, -- invert readings
        set_float = false,
        debounceMs = 5,
    },
}

local door_switch = {
    name = "door_switch",
    type = "switch-gpio",
    internal = false,
    spec = {
        name = "my switch",
    },
    settings = {
        pin = 2,
        inverted = false,
        set_float = false,
        is_on = false,
    },
}

local valve_control_loop = {
    name = "valve_control_loop",
    type = "switch-func",
    internal = false,
    spec = {
        name = "my switch control loop",
    },
    settings = {
        funcname = "fnc-gated-switch",
        scheduleMs = 5,
        sensorId = "door_sensor",
        switchId = "door_switch",
        is_on = true,
        cache = true,
    },
}

local function assertPlainInput()
    -- assert plain gpio input
    local pin = 1
    local inputFn = require("dev-" .. door_sensor.name)
    inputFn(nil, true)                -- setup
    lu.assertEquals(nodemcu.gpio_get_mode(pin), gpio.INPUT)
    lu.assertEquals(inputFn(), true)  -- get, true is default nodemcu value
    nodemcu.gpio_set(pin, 1)
    lu.assertEquals(inputFn(), true)  -- get
    nodemcu.gpio_set(pin, 0)
    lu.assertEquals(inputFn(), false) -- get
end

local function assertBounceInput()
    -- assert bouncing gpio input, inverted values
    local pin = 3
    local inputFn = require("dev-" .. water_sensor.name)
    inputFn(nil, true)                -- setup
    lu.assertEquals(nodemcu.gpio_get_mode(pin), gpio.INPUT)
    lu.assertEquals(inputFn(), false) -- get, true is default nodemcu value
    nodemcu.advanceTime(10)
    nodemcu.gpio_set(pin, 1)
    lu.assertEquals(inputFn(), false) -- get
    nodemcu.gpio_set(pin, 0)
    nodemcu.advanceTime(10)
    lu.assertEquals(inputFn(), true) -- get
end

local function assertSwitch(pin2)
    -- assert switch on-off sequence
    local switchFn = require("dev-" .. door_switch.name)
    switchFn(nil, true)                                 -- setup
    lu.assertEquals(nodemcu.gpio_get_mode(2), gpio.OUTPUT)
    lu.assertEquals(switchFn({ is_on = true }), true)   -- set
    lu.assertEquals(switchFn({ is_on = false }), false) -- set
    lu.assertEquals(pin2, { 1, 0 })                     -- get
end

local function assertDeviceFiles()
    lu.assertEquals(require("device-settings")("dev-info"), devinfo)
    lu.assertEquals(require("device-settings")("dev-list"), {
        "door_sensor",
        "door_switch",
        "water_sensor",
        "valve_control_loop",
    })
    lu.assertEquals(require("device-settings")("dev-hass-list"), {
        "door_sensor",
        "door_switch",
        "valve_control_loop",
    })
end

local function assertSwitchGateFunc(pin2)
    local sensorPin = 1
    nodemcu.gpio_set(sensorPin, 1) -- prepare sensor to on
    local switchFn = require("dev-" .. valve_control_loop.name)
    switchFn(nil, true)            -- setup
    nodemcu.advanceTime(10)
    lu.assertEquals(pin2, { 1 })
    nodemcu.advanceTime(10)         -- one control loop with no change
    lu.assertEquals(pin2, { 1 })
    nodemcu.gpio_set(sensorPin, 0)  -- set sensor to off
    nodemcu.advanceTime(10)
    lu.assertEquals(pin2, { 1, 0 }) -- and switch is off too
end

function testOk()
    nodemcu.reset()
    removeDevFiles()

    local pin2 = {}
    nodemcu.gpio_capture(2, function(_, val)
        table.insert(pin2, val)
    end)

    local fn = require("device-factory")
    fn({
        info = devinfo,
        devices = {
            door_sensor,
            door_switch,
            water_sensor,
            valve_control_loop,
        },
    })

    assertDeviceFiles()
    assertSwitch(pin2)
    assertPlainInput()
    assertBounceInput()
    pin2 = {}
    assertSwitchGateFunc(pin2)
end

os.exit(lu.run())
