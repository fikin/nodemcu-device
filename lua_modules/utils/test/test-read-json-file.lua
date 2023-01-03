local lu = require("luaunit")
local nodemcu = require("nodemcu")

local fn = require("read-json-file")

function testOk()
  nodemcu.reset()

  local file = require("file")
  lu.assertIsTrue(file.putcontents("o.json", '{"a":1,"b":{"c":2}}'))
  local o = fn("o.json")
  lu.assertEquals(o.a, 1)
  lu.assertEquals(o.b.c, 2)
  file.remove("o.json")
end

function testMissingFile()
  nodemcu.reset()

  local function boom()
    return fn("ohoo.json")
  end

  local err = lu.LuaUnit:protectedCall(nil, boom, "kaboom")
  lu.assertEquals(err.status, "ERROR")
  lu.assertStrContains(err.msg, "missing file")
end

os.exit(lu.run())
