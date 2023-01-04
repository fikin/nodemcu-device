local lu = require("luaunit")
local nodemcu = require("nodemcu")

local file = require("file")

---test that LFS.img is LFS.reload() and error is captured.
---as node.LFS.reload() is not possible to implement currently.
local function assertLFSFileError()
    lu.assertEquals(file.getcontents("LFS.img.PANIC.txt"), "FIXME : not implemented")
    lu.assertIsFalse(file.exists("LFS.img"))
end

local function assertDeviSettingsFile()
    lu.assertIsTrue(file.exists("device-settings.json"))
    lu.assertIsFalse(file.exists("device-settings.json.bak"))
end

local function assertWifiPortal()
    local skt = nodemcu.net_tpc_connect_to_listener(80, "0.0.0.0")
    skt:sentByRemote('GET /device-settings.json HTTP/1.0\r\nAuthorization: Basic YWRtaW46YWRtaW4=\r\n\r\n')
    nodemcu.advanceTime(500)
    local sent = table.concat(skt:receivedByRemoteAll(), "")
    local expected = 'HTTP/1.0 200 OK\r\n' ..
        'Cache-Control: private, no-cache, no-store\r\n' ..
        'Content-Length: ' .. file.stat("device-settings.json").size .. '\r\n' ..
        'Content-Type: application/json\r\n' ..
        '\r\n' ..
        file.getcontents("device-settings.json")
    lu.assertEquals(sent, expected)
end

local function assertHassInfo()
    local skt = nodemcu.net_tpc_connect_to_listener(80, "0.0.0.0")
    skt:sentByRemote('GET /api/ha/info HTTP/1.0\r\nAuthorization: Basic aGFzczphZG1pbg==\r\n\r\n')
    nodemcu.advanceTime(500)
    local sent = table.concat(skt:receivedByRemoteAll(), "")
    local expected = 'HTTP/1.0 200 OK\r\n' ..
        'Cache-Control: private, no-cache, no-store\r\n' ..
        'Content-Length: 120\r\n' ..
        'Content-Type: application/json\r\n' ..
        '\r\n' ..
        '{"hwVersion":"1.0.0","manufacturer":"fikin","model":"WeMos D1 mini","name":"nodemcu1234567890","swVersion":"1669271656"}'
    lu.assertEquals(sent, expected)
end

local function assertHassSpec()
    local skt = nodemcu.net_tpc_connect_to_listener(80, "0.0.0.0")
    skt:sentByRemote('GET /api/ha/spec HTTP/1.0\r\nAuthorization: Basic aGFzczphZG1pbg==\r\n\r\n')
    nodemcu.advanceTime(500)
    local sent = table.concat(skt:receivedByRemoteAll(), "")
    local expected = 'HTTP/1.0 200 OK\r\n' ..
        'Cache-Control: private, no-cache, no-store\r\n' ..
        'Content-Length: 273\r\n' ..
        'Content-Type: application/json\r\n' ..
        '\r\n' ..
        '{"climate":[{"key":"thermostat","name":"Thermostat"}],"sensor":[{"device_class":"temperature","key":"temp-sensor","name":"Temperature","native_unit_of_measurement":"°C","state_class":"measurement"}],"switch":[{"device_class":"switch","key":"relay-switch","name":"Relay"}]}'
    lu.assertEquals(sent, expected)
end

local function assertHassData()
    local skt = nodemcu.net_tpc_connect_to_listener(80, "0.0.0.0")
    skt:sentByRemote('GET /api/ha/data HTTP/1.0\r\nAuthorization: Basic aGFzczphZG1pbg==\r\n\r\n')
    nodemcu.advanceTime(500)
    local sent = table.concat(skt:receivedByRemoteAll(), "")
    local expected = 'HTTP/1.0 200 OK\r\n' ..
        'Cache-Control: private, no-cache, no-store\r\n' ..
        'Content-Length: 343\r\n' ..
        'Content-Type: application/json\r\n' ..
        '\r\n' ..
        '{"relay-switch":{"is_on":false},"temp-sensor":{"native_value":22},"thermostat":{"current_temperature":22,"hvac_action":"off","hvac_mode":"off","hvac_modes":["off","heat","auto"],"preset_mode":"away","preset_modes":["away","day","night"],"supported_features":2,"target_temperature_high":17,"target_temperature_low":15,"temperature_unit":"°C"}}'
    lu.assertEquals(sent, expected)
end

local function assertHass()
    assertHassInfo()
    assertHassSpec()
    assertHassData()
end

function testInit()
    nodemcu.reset()

    lu.assertIsTrue(file.exists("LFS.img"))
    lu.assertIsFalse(file.exists("LFS.img.PANIC.txt"))
    lu.assertIsFalse(file.exists("device-settings.json"))

    require("init")
    nodemcu.advanceTime(2000)

    assertLFSFileError()
    assertDeviSettingsFile()
    assertWifiPortal()
    assertHass()
end

os.exit(lu.run())
