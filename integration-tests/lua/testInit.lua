local lu = require("luaunit")
local nodemcu = require("nodemcu")

local file = require("file")
local sjson = require("sjson")

---test that LFS.img is LFS.reload() and error is captured.
---as node.LFS.reload() is not possible to implement currently.
local function assertLFSFileError()
    lu.assertEquals(file.getcontents("LFS.img.PANIC.txt"), "FIXME : not implemented")
    lu.assertIsFalse(file.exists("LFS.img"))
end

local function assertDeviSettingsFile()
    lu.assertIsTrue(file.exists("fs-wifi.json"))
    lu.assertIsFalse(file.exists("ds-wifi.json"))
    lu.assertIsFalse(file.exists("ds-wifi.json.bak"))
end

local function assert200HttpRequest(request, expected)
    local skt = nodemcu.net_tpc_connect_to_listener(80, "0.0.0.0")
    skt:sentByRemote(request)
    nodemcu.advanceTime(500)
    local sent = table.concat(skt:receivedByRemoteAll(), "")
    lu.assertEquals(sent, expected)
end

local function assertWifiPortalGetCfgWifi()
    local cfg = require("device-settings")("wifi")
    local cfgTxt = require("sjson").encode(cfg)
    local r = 'GET /wifi-portal-ds/wifi HTTP/1.0\r\nAuthorization: Basic YWRtaW46YWRtaW4=\r\n\r\n'
    local e = 'HTTP/1.0 200 OK\r\n' ..
        'Cache-Control: private, no-cache, no-store\r\n' ..
        'Content-Length: ' .. #cfgTxt .. '\r\n' ..
        'Content-Type: application/json\r\n' ..
        '\r\n' ..
        cfgTxt
    assert200HttpRequest(r, e)
end

local function assertWifiPortalRestart()
    local r = 'POST /wifi-portal-ds/.restart HTTP/1.0\r\nAuthorization: Basic YWRtaW46YWRtaW4=\r\n\r\n'
    local e = 'HTTP/1.0 200 OK\r\n' ..
        '\r\n'
    assert200HttpRequest(r, e)
    lu.assertIsTrue(nodemcu.node.restartRequested)
end

local function assertWifiPortal()
    assertWifiPortalGetCfgWifi()
    assertWifiPortalRestart()
end

local function assertHassInfo()
    local r = 'GET /api/ha/info HTTP/1.0\r\nAuthorization: Basic aGFzczphZG1pbg==\r\n\r\n'
    local e = 'HTTP/1.0 200 OK\r\n' ..
        'Cache-Control: private, no-cache, no-store\r\n' ..
        'Content-Length: 120\r\n' ..
        'Content-Type: application/json\r\n' ..
        '\r\n' ..
        '{"hwVersion":"1.0.0","manufacturer":"fikin","model":"WeMos D1 mini","name":"nodemcu1234567890","swVersion":"1669271656"}'
    assert200HttpRequest(r, e)
end

local function assertHassSpec()
    local r = 'GET /api/ha/spec HTTP/1.0\r\nAuthorization: Basic aGFzczphZG1pbg==\r\n\r\n'
    local e = 'HTTP/1.0 200 OK\r\n' ..
        'Cache-Control: private, no-cache, no-store\r\n' ..
        'Content-Length: 676\r\n' ..
        'Content-Type: application/json\r\n' ..
        '\r\n' ..
        '{"button":[{"device_class":"restart","key":"system-restart-button","name":"Restart"}],"climate":[{"key":"thermostat","name":"Thermostat"}],"light":[{"key":"lights-switch","name":"Lights"}],"sensor":[{"device_class":"temperature","key":"temp-sensor","name":"Temperature","native_unit_of_measurement":"°C","state_class":"measurement"},{"device_class":"data_size","key":"system-heap-sensor","name":"Heap","native_unit_of_measurement":"B","state_class":"measurement"},{"device_class":"current","key":"sct013-sensor-0-current","name":"Current","native_unit_of_measurement":"A","state_class":"measurement"}],"switch":[{"device_class":"switch","key":"relay-switch","name":"Relay"}]}'
    assert200HttpRequest(r, e)
end

local function assertHassData()
    local r = 'GET /api/ha/data HTTP/1.0\r\nAuthorization: Basic aGFzczphZG1pbg==\r\n\r\n'
    local e = 'HTTP/1.0 200 OK\r\n' ..
        'Cache-Control: private, no-cache, no-store\r\n' ..
        'Content-Length: 522\r\n' ..
        'Content-Type: application/json\r\n' ..
        '\r\n' ..
        '{"lights-switch":{"color_mode":"onoff","is_on":false,"supported_color_modes":["onoff"]},"relay-switch":{"is_on":false},"sct013-sensor-0-current":{"native_value":0.0},"system-heap-sensor":{"native_value":32096},"temp-sensor":{"native_value":22},"thermostat":{"current_temperature":22,"hvac_action":"off","hvac_mode":"off","hvac_modes":["off","heat","auto"],"preset_mode":"away","preset_modes":["away","home","sleep"],"supported_features":2,"target_temperature_high":17,"target_temperature_low":15,"temperature_unit":"°C"}}'
    assert200HttpRequest(r, e)
end

local function assertThermostatMode()
    ---@type thermostat_cfg
    local stS = require("state")("thermostat")

    local function assertValues(v1, v2, tgt)
        lu.assertEquals(v1, tgt)
        lu.assertEquals(v2, tgt)
    end

    assertValues(stS.data.hvac_mode, require("device-settings")("thermostat").data.hvac_mode, "off")

    local txt = sjson.encode({ thermostat = { hvac_mode = "auto" } })
    local r = 'POST /api/ha/data HTTP/1.0\r\n' ..
        'Authorization: Basic aGFzczphZG1pbg==\r\n' ..
        'Content-Type: application/json\r\n' ..
        'Content-Length: ' .. tostring(#txt) .. '\r\n' ..
        '\r\n' ..
        txt
    local e = 'HTTP/1.0 200 OK\r\n' .. '\r\n'
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

    assertValues(stS.data, 17, 15)
    local devSet = require("device-settings")("thermostat")
    assertValues(devSet.data, 17, 15)

    local txt = sjson.encode({ thermostat = { target_temperature_high = 33, target_temperature_low = 11 } })
    local r = 'POST /api/ha/data HTTP/1.0\r\n' ..
        'Authorization: Basic aGFzczphZG1pbg==\r\n' ..
        'Content-Type: application/json\r\n' ..
        'Content-Length: ' .. tostring(#txt) .. '\r\n' ..
        '\r\n' ..
        txt
    local e = 'HTTP/1.0 200 OK\r\n' .. '\r\n'
    assert200HttpRequest(r, e)

    assertValues(stS.data, 33, 11)
    local devS = require("device-settings")("thermostat")
    assertValues(devS.data, 33, 11)
    assertValues(devS.modes[devS.data.preset_mode], 33, 11)
end

local function assertHass()
    assertHassInfo()
    assertHassSpec()
    assertHassData()
    assertThermostatMode()
    assertThermostatPresetRanges()
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
    assertSktSendReceived(skt, "telnet", "Enter password:")
    assertSktSendReceived(skt, "dummy", "Enter username:")
    assertSktSendReceived(skt, "telnet", "Enter password:")
    assertSktSendReceived(skt, "admin", "") -- this is now deviating from actual device, as node.output() is not properly captured in mock setup
    assertSktSendReceived(skt, "return 'abc'", "abc\n")
end

function testInit()
    nodemcu.reset()

    --lu.assertIsTrue(file.exists("LFS.img"))
    lu.assertIsFalse(file.exists("LFS.img.PANIC.txt"))
    lu.assertIsTrue(file.exists("fs-wifi.json"))
    lu.assertIsFalse(file.exists("ds-wifi.json"))

    require("init")
    nodemcu.advanceTime(2000)

    assertLFSFileError()
    assertDeviSettingsFile()
    assertWifiPortal()
    assertHass()
    assertTelnet()
end

os.exit(lu.run())
