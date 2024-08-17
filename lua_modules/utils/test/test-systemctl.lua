local lu = require("luaunit")
local nodemcu = require("nodemcu")

function testOk()
    nodemcu.reset()

    local fn = require("systemctl")

    fn.require("crc8")
    -- fn.fnc("first", function() require("crc8") end)
    local called = false
    fn.fnc("second", function() called = true end)
    fn.fnc("third", function() error("fail me") end)
    fn:start()
    lu.assertEquals(#fn:services(), 3)
    lu.assertIsTrue(called)
    lu.assertEquals(fn:status(), "failed")
    lu.assertEquals(fn:services()[1], { name = "crc8", status = "ok" })
    lu.assertEquals(fn:services()[2], { name = "second", status = "ok" })
    lu.assertStrContains(fn:services()[3].name, "third")
    lu.assertStrContains(fn:services()[3].status, "failed")
    lu.assertStrContains(fn:services()[3].err, "fail me")
end

os.exit(lu.run())
