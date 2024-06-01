local lu = require("luaunit")

local nodemcu = require("nodemcu")
local fn = require("rtc-state")

function testGeneric()
    nodemcu.reset()
    lu.assertError(fn)
    lu.assertError(fn, "A")
end

function testTime()
    nodemcu.reset()
    local rw = fn("time")
    lu.assertError(rw, 1)
    local ok, val = rw()
    lu.assertFalse(ok)
    lu.assertNotIsNaN(val)
    ok, _ = rw(nil, 0xABCDEF12)
    lu.assertTrue(ok)
    ok, val = rw()
    lu.assertTrue(ok)
    lu.assertEquals(val, 0xABCDEF12)

    ok, val = fn("time")()
    lu.assertTrue(ok)
    lu.assertEquals(val, 0xABCDEF12)
end

local function assertByte(modulename)
    nodemcu.reset()
    local rw = fn(modulename)
    lu.assertError(rw, modulename, -1)
    lu.assertError(rw, modulename, 0)
    lu.assertError(rw, modulename, 5)
    local ok, val = rw(1)
    lu.assertFalse(ok)
    lu.assertNotIsNaN(val)
    ok, val = rw(1, 0xF12)
    lu.assertTrue(ok)
    lu.assertEquals(val, 0x12)
    ok, val = rw(1)
    lu.assertTrue(ok)
    lu.assertEquals(val, 0x12)
end

function testBootprotect()
    assertByte("bootprotect")
end

function testTemp()
    assertByte("temperature")
end

function testHumidity()
    assertByte("humidity")
end

os.exit(lu.run())
