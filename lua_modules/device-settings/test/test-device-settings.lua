local lu = require("luaunit")
local nodemcu = require("nodemcu")
local file = require("file")

local fs = require("factory-settings")
local ds = require("device-settings")

function testOk()
    nodemcu.reset()

    file.remove("ds-dummy.json")
    file.remove("fs-dummy.json")

    -- prepare files
    local b = fs("dummy")
    b:set("a.b", "bb")
    b:set("a.c", "cc")
    b:set("d", "dd")
    b:done()
    lu.assertIsTrue(file.rename("ds-dummy.json", "fs-dummy.json"))
    b = fs("dummy")
    b:set("a.c", "11")
    b:done()

    local o = ds("dummy")
    lu.assertNotIsNil(o.a)
    lu.assertEquals(o.a.b, "bb")
    lu.assertEquals(o.a.c, "11")
    lu.assertEquals(o.d, "dd")
end

os.exit(lu.run())
