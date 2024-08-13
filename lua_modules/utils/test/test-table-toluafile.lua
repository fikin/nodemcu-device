local lu = require("luaunit")
local nodemcu = require("nodemcu")
local file = require("file")

local fn = require("table-toluafile")

function testOk()
  nodemcu.reset()

  local t1 = { a = "b", c = { d = 2 } }
  fn("test-luafile", t1, true)

  local str = file.getcontents("test-luafile.lua")
  local t2, err = load(str)
  lu.assertIsNil(err)
  lu.assertEquals(t2(), t1)
  lu.assertIsTrue( file.exists("test-luafile.lc") )
end

os.exit(lu.run())
