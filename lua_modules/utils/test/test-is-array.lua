local lu = require("luaunit")

local fn = require("is-array")

function testOk()
    lu.assertIsFalse(fn({}))
    lu.assertIsTrue(fn({ 1, 2, 3 }))
    lu.assertIsTrue(fn({ "1", "2", "3" }))
    lu.assertIsFalse(fn({ ["1"] = 1,["2"] = 2 }))
end

os.exit(lu.run())
