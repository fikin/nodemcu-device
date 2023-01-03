local lu = require("luaunit")

local fn = require("str-to-json")

function testObjectOk()
    local o = fn('{ "a": 1, "b":{ "c": "c1", "d": null }, "e":null }')
    lu.assertEquals(o, { a = 1, b = { c = "c1" } })
end

function testArrayOk()
    local o = fn('[1, 2, null, 4]')
    lu.assertEquals(o, { 1, 2, 4 })
end

os.exit(lu.run())
