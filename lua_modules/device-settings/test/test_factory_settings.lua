local lu = require("luaunit")
local nodemcu = require("nodemcu")
local file = require("file")
local sjson = require("sjson")

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

function testInitSeq()
  nodemcu.reset()

  local b = fn("init-seq")

  local o2 = sjson.decode('{"bootsequence":["user-settings"]}')
  b:mergeTblInto(nil, o2)
  b:done()

  local o3 = require("device-settings")("init-seq")
  lu.assertEquals(o3, { ["bootsequence"] = { "user-settings" } })
end

os.exit(lu.run())
