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
    nodemcu.advanceTime(1000)
    local sent = table.concat(skt:receivedByRemoteAll(), "")
    local expected = 'HTTP/1.0 200 OK\r\n' ..
        'Cache-Control: private, no-cache, no-store\r\n' ..
        'Content-Length: ' .. file.stat("device-settings.json").size .. '\r\n' ..
        'Content-Type: application/json\r\n' ..
        '\r\n' ..
        file.getcontents("device-settings.json")
    lu.assertEquals(sent, expected)
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
end

os.exit(lu.run())
