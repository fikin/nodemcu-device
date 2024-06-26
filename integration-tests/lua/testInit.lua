local lu = require("luaunit")
local nodemcu = require("nodemcu")

local file = require("file")
local sjson = require("sjson")

local function nl(str)
    return string.gsub(str, "\n", "\r\n")
end

-- test that reboot is initiated after LFS.img is reloaded ok
local function assertLFSReload()
    require("init")
    local ok, err = pcall(nodemcu.advanceTime, 2000)
    lu.assertIsFalse(ok)
    lu.assertStrContains(err, "node.LFS.reload")
    -- simulate node.LFS.reload removal of image file
    file.remove("LFS.img")
end

local function assertNormalBootAfterLFSReload()
    require("init")
    nodemcu.advanceTime(2000)
end

local function assertSpiffsContent()
    lu.assertIsFalse(file.exists("LFS.img.PANIC.txt"))
    lu.assertIsTrue(file.exists("LFS.img"))
    lu.assertIsTrue(file.exists("fs-wifi.json"))
    lu.assertIsFalse(file.exists("ds-wifi.json"))
    lu.assertIsFalse(file.exists("ds-wifi.json.bak"))
end

local function sendHttpRequest(request)
    local skt = nodemcu.net_tpc_connect_to_listener(80, "0.0.0.0")
    skt:sentByRemote(request)
    nodemcu.advanceTime(500)
    return table.concat(skt:receivedByRemoteAll(), "")
end

local function assert200HttpRequest(request, expected)
    local received = sendHttpRequest(request)
    lu.assertEquals(received, expected)
end

local function slimJsonBody200Resp(txt)
    local str = sjson.encode(sjson.decode(txt))
    return nl([[HTTP/1.0 200 OK
Cache-Control: private, no-cache, no-store
Content-Length: ]]) .. #str ..
        nl([[

Content-Type: application/json

]] .. str)
end

local function assertWifiPortalGetCfgWifi()
    local cfg = require("device-settings")("wifi")
    local cfgTxt = require("sjson").encode(cfg)
    local r = nl([[GET /wifi-portal-ds/wifi HTTP/1.0
Authorization: Basic YWRtaW46YWRtaW4=

]])
    local e = nl([[HTTP/1.0 200 OK
Cache-Control: private, no-cache, no-store
Content-Length: ]]) .. #cfgTxt ..
        nl([[

Content-Type: application/json

]] .. cfgTxt)
    assert200HttpRequest(r, e)
end

local function assertWifiPortalRestart()
    local r = nl([[POST /wifi-portal-ds/.restart HTTP/1.0
Authorization: Basic YWRtaW46YWRtaW4=

]])
    local e = nl([[HTTP/1.0 200 OK

]])
    assert200HttpRequest(r, e)
    lu.assertIsTrue(nodemcu.node.restartIgnored)
    nodemcu.node.restartIgnored = false
end

local function assertWifiPortal()
    assertWifiPortalGetCfgWifi()
    assertWifiPortalRestart()
end

local function assertHassInfo()
    local r = nl([[GET /api/ha/info HTTP/1.0
Authorization: Basic aGFzczphZG1pbg==

]])
    local e = slimJsonBody200Resp([[
{
    "hwVersion": "1.0.0",
    "manufacturer": "Noname vendor",
    "model": "Generic NodeMCU make",
    "name": "nodemcu1234567890",
    "swVersion": "1669271656"
}]])
    assert200HttpRequest(r, e)
end

local function assertHassSpec()
    local r = nl([[GET /api/ha/spec HTTP/1.0
Authorization: Basic aGFzczphZG1pbg==

]])
    local e = slimJsonBody200Resp([[
{
    "button": [
        {
        "device_class": "restart",
        "key": "system-restart-button",
        "name": "Restart"
        }
    ],
    "climate": [
        {
        "key": "thermostat",
        "name": "Thermostat"
        }
    ],
    "light": [
        {
        "key": "lights-switch",
        "name": "Lights"
        }
    ],
    "sensor": [
        {
        "device_class": "temperature",
        "key": "temp-sensor",
        "name": "Temperature",
        "native_unit_of_measurement": "°C",
        "state_class": "measurement"
        },
        {
        "device_class": "data_size",
        "key": "system-heap-sensor",
        "name": "Heap",
        "native_unit_of_measurement": "B",
        "state_class": "measurement"
        },
        {
        "device_class": "current",
        "key": "sct013-sensor",
        "name": "Current",
        "native_unit_of_measurement": "A",
        "state_class": "measurement"
        }
    ],
    "switch": [
        {
        "device_class": "switch",
        "key": "relay-switch",
        "name": "Relay"
        }
    ]
}]])
    assert200HttpRequest(r, e)
end

local function assertHassData()
    local r = nl([[GET /api/ha/data HTTP/1.0
Authorization: Basic aGFzczphZG1pbg==

]])
    local e = slimJsonBody200Resp([[
{
    "lights-switch": {
      "color_mode": "onoff",
      "is_on": false,
      "supported_color_modes": [
        "onoff"
      ]
    },
    "relay-switch": {
      "is_on": false
    },
    "sct013-sensor": {
      "native_value": 0.0
    },
    "system-heap-sensor": {
      "native_value": 32096
    },
    "temp-sensor": {
      "native_value": 22
    },
    "thermostat": {
      "current_temperature": 22,
      "hvac_action": "off",
      "hvac_mode": "off",
      "hvac_modes": [
        "off",
        "heat",
        "auto"
      ],
      "preset_mode": "away",
      "preset_modes": [
        "away",
        "home",
        "sleep"
      ],
      "supported_features": 18,
      "target_temperature_high": 20,
      "target_temperature_low": 18,
      "temperature_unit": "°C"
    }
  }]])
    assert200HttpRequest(r, e)
end

---forms HASS POST request
---@param obj table
---@return string
local function newHASSPOST(obj)
    local txt = sjson.encode(obj)
    local r = nl([[POST /api/ha/data HTTP/1.0
Authorization: Basic aGFzczphZG1pbg==
Content-Type: application/json
Content-Length: ]]) .. tostring(#txt) .. "\r\n\r\n" .. txt
    return r
end

local function assertThermostatMode()
    ---@type thermostat_cfg
    local stS = require("state")("thermostat")

    local function assertValues(v1, v2, tgt)
        lu.assertEquals(v1, tgt)
        lu.assertEquals(v2, tgt)
    end

    assertValues(stS.data.hvac_mode, require("device-settings")("thermostat").data.hvac_mode, "off")

    local r = newHASSPOST({ thermostat = { hvac_mode = "auto" } })
    local e = 'HTTP/1.0 200 OK\r\n\r\n'
    assert200HttpRequest(r, e)

    assertValues(stS.data.hvac_mode, require("device-settings")("thermostat").data.hvac_mode, "auto")
end

local function assertThermostatPresetRanges()
    ---@type thermostat_cfg
    local stS = require("state")("thermostat")

    local function assertValues(v1, tgt1, tgt2)
        lu.assertEquals(v1.target_temperature_high, tgt1)
        lu.assertEquals(v1.target_temperature_low, tgt2)
    end

    assertValues(stS.data, 20, 18)
    local devSet = require("device-settings")("thermostat")
    assertValues(devSet.data, 20, 18)

    local r = newHASSPOST({ thermostat = { target_temperature_high = 33, target_temperature_low = 11 } })
    local e = 'HTTP/1.0 200 OK\r\n\r\n'
    assert200HttpRequest(r, e)

    assertValues(stS.data, 33, 11)
    local devS = require("device-settings")("thermostat")
    assertValues(devS.data, 33, 11)
    assertValues(devS.modes[devS.data.preset_mode], 33, 11)
end

local function assertRelaySwitchIsOn()
    ---@type relay_switch_cfg
    local cfg = require("device-settings")("relay-switch")

    local state = require("relay")(cfg.relay)

    lu.assertFalse(state())

    local r = newHASSPOST({ ["relay-switch"] = { is_on = true } })
    local e = 'HTTP/1.0 200 OK\r\n\r\n'
    assert200HttpRequest(r, e)

    lu.assertTrue(state())
end

local function assertLightIsOn()
    ---@type lights_switch_cfg
    local cfg = require("device-settings")("relay-switch")

    local state = require("relay")(cfg.relay)

    -- opposite value to relay
    -- as assertRelaySwitchIsOn() is called before this ione
    lu.assertTrue(state())

    local r = newHASSPOST({ ["lights-switch"] = { is_on = false } })
    local e = 'HTTP/1.0 200 OK\r\n\r\n'
    assert200HttpRequest(r, e)

    lu.assertFalse(state())
end

local function assertHass()
    assertHassInfo()
    assertHassSpec()
    assertHassData()
    assertThermostatMode()
    assertThermostatPresetRanges()
    assertRelaySwitchIsOn()
    assertLightIsOn()
end

local function assertSktReceived(skt, expected)
    nodemcu.advanceTime(100)
    local sent = table.concat(skt:receivedByRemote(), "")
    lu.assertEquals(sent, expected)
end

local function assertSktSendReceived(skt, send, expected)
    skt:sentByRemote(send, false)
    assertSktReceived(skt, expected)
end

local function assertTelnet()
    local skt = nodemcu.net_tpc_connect_to_listener(23, "0.0.0.0")
    assertSktReceived(skt, "Enter username:")
    assertSktSendReceived(skt, "dummy", "Enter username:")
    assertSktSendReceived(skt, "admin", "Enter password:")
    assertSktSendReceived(skt, "dummy", "Enter username:")
    assertSktSendReceived(skt, "admin", "Enter password:")
    assertSktSendReceived(skt, "admin", "") -- this is now deviating from actual device,
    -- as node.output() is not properly captured in mock setup
    assertSktSendReceived(skt, "return 'abc'", "abc\n")
end

function testInit()
    nodemcu.reset()

    assertSpiffsContent()
    assertLFSReload()
    assertNormalBootAfterLFSReload()
    NODEMCU_RESTART_IGNORE = true
    assertWifiPortal()
    assertHass()
    assertTelnet()
    _G["NODEMCU_RESTART_IGNORE"] = nil
end

os.exit(lu.run())
