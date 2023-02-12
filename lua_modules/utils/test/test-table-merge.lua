local lu = require("luaunit")

local tm = require("table-merge")

function testNewTbl()
  local o = {}
  tm(o, { a = 1, b = { c = 2 } })
  lu.assertEquals(o, { a = 1, b = { c = 2 } })
end

function testAppend()
  local o = { d = 4 }
  tm(o, { a = 1, b = { c = 2 } })
  lu.assertEquals(o, { a = 1, b = { c = 2 }, d = 4 })
end

function testOverwrite()
  local o = { a = 5 }
  tm(o, { a = 1, b = { c = 2 } })
  lu.assertEquals(o, { a = 1, b = { c = 2 } })
end

function testArray()
  local o = { ["mod"] = { 1, 2, 3 },["remain"] = true }
  tm(o, { ["mod"] = { 1 },["added"] = true })
  lu.assertEquals(o, { ["mod"] = { 1 },["added"] = true,["remain"] = true })
end

function testArray2()
  local o = { ["mod"] = { "1", "2", "3" },["remain"] = true }
  tm(o, { ["mod"] = { "1", "9" },["added"] = true })
  lu.assertEquals(o, { ["mod"] = { "1", "9" },["added"] = true,["remain"] = true })
end

os.exit(lu.run())
