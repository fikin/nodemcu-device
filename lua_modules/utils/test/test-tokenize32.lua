local lu = require("luaunit")

local fn = require("tokenize32")

function testOk()
  lu.assertEquals(table.pack(fn(0xABCDEF12)), table.pack(0xAB, 0xCD, 0xEF, 0x12))
  lu.assertEquals(table.pack(fn(17)), table.pack(0x00, 0x00, 0x00, 0x11))
end

os.exit(lu.run())
