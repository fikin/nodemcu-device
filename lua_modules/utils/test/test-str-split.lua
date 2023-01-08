local lu = require("luaunit")

local fn = require("str-split")

function testObjectOk()
    local o = fn("1 2 3 4 5 ", " ")
    lu.assertEquals(o, { "1", "2", "3", "4", "5", "" })

    o = fn("Content-Type: application/json", ": ")
    lu.assertEquals(o, { "Content-Type", "application/json" })

    o = fn("a: b\r\nc: d d\r\n d dd\r\n\r\n", "\r\n")
    lu.assertEquals(o, { "a: b", "c: d d", " d dd", "", "" })

    o = fn(" application/json", ": ")
    lu.assertEquals(o, { " application/json" })
end

os.exit(lu.run())
