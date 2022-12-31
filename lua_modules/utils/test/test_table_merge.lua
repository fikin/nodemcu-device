local lu = require("luaunit")

local tm = require("table_merge")

function testNewTbl()
  local o = {}
  tm(o, {a = 1, b = {c = 2}})
  lu.assertEquals(o.a, 1)
  lu.assertEquals(o.b.c, 2)
end

function testAppend()
  local o = {d = 4}
  tm(o, {a = 1, b = {c = 2}})
  lu.assertEquals(o.a, 1)
  lu.assertEquals(o.b.c, 2)
  lu.assertEquals(o.d, 4)
end

function testOverwrite()
  local o = {a = 5}
  tm(o, {a = 1, b = {c = 2}})
  lu.assertEquals(o.a, 1)
  lu.assertEquals(o.b.c, 2)
end

os.exit(lu.run())
