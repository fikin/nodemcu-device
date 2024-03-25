local lu = require("luaunit")

local fn = require("crc8")

function testOk()
    lu.assertEquals(0, fn())
    lu.assertEquals(0, fn({}))
    lu.assertEquals(0, fn({ 0 }))
    lu.assertEquals(0, fn({ 0, 0, 0 }))
    lu.assertEquals(fn({ 1, 2 }), fn({ 1, 2 }))
    lu.assertNotEquals(fn({ 2, 1 }), fn({ 1, 2 }))
    lu.assertEquals(fn({ 97, 98, 99 }), fn("abc"))
    lu.assertEquals(fn("abc"), 66)
    lu.assertEquals(fn("ab"), 71)
    lu.assertEquals(fn("a"), 59)
    lu.assertEquals(fn({ 97 }), 59)
end

os.exit(lu.run())
