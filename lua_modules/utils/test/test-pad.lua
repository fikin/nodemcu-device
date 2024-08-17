local lu = require("luaunit")


function testLpad()
    local fn = require("lpad")
    lu.assertEquals(fn("1", -1, "0"), "1")
    lu.assertEquals(fn("1", 0, "0"), "1")
    lu.assertEquals(fn("1", 1, "0"), "1")
    lu.assertEquals(fn("1", 2, "0"), "01")
end

function testRpad()
    local fn = require("rpad")
    lu.assertEquals(fn("1", -1, "0"), "1")
    lu.assertEquals(fn("1", 0, "0"), "1")
    lu.assertEquals(fn("1", 1, "0"), "1")
    lu.assertEquals(fn("1", 2, "0"), "10")
end

os.exit(lu.run())
