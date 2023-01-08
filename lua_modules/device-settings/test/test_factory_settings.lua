local lu = require("luaunit")
local nodemcu = require("nodemcu")
local file = require("file")

local fn = require("factory-settings")

function testOk()
  nodemcu.reset()

  local b = fn("dummy")

  lu.assertNotIsNil(b.cfg)

  b:set("a.b", "cc")
  lu.assertEquals(b.cfg.a.b, "cc")

  b:set("d", "dd")
  lu.assertEquals(b.cfg.d, "dd")

  b:unset("d")
  lu.assertIsNil(b.cfg.d)

  b:done()
  lu.assertIsTrue(file.exists("ds-dummy.json"))
end

os.exit(lu.run())
