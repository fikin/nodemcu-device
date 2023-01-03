local lu = require("luaunit")
local nodemcu = require("nodemcu")

function testOk()
  nodemcu.reset()

  local fn = require("factory-settings")

  lu.assertNotIsNil(fn.cfg)
  lu.assertNotIsNil(fn.cfg.sta.hostname)

  fn.set("sta.hostname", "aa")
  lu.assertEquals(fn.cfg.sta.hostname, "aa")

  fn.set("sta.sleepType", 33)
  lu.assertEquals(fn.cfg.sta.sleepType, 33)

  local o = { a = 1 }
  fn.set("dummy.one", o)
  lu.assertEquals(fn.cfg.dummy.one, o)

  fn.default("sta.sleepType", 44)
  lu.assertEquals(fn.cfg.sta.sleepType, 33)
  fn.default("sta.hostname", "44")
  lu.assertEquals(fn.cfg.sta.hostname, "aa")
  fn.default("sta.config.pwd", "ppp")
  lu.assertEquals(fn.get("sta.config.pwd"), "ppp")

  lu.assertIsNil(fn.cfg.dummy.two)
  lu.assertIsNil(fn.get("dummy.two.b"))
  lu.assertEquals(fn.get("dummy.two"), {})

end

os.exit(lu.run())
