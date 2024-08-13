local lu = require("luaunit")

local fn = require("table-tostring")

function testOk()
  lu.assertEquals(fn({}), [[{
}]])
  lu.assertEquals(fn(1), [[1]])
  lu.assertEquals(fn("1"), [["1"]])
  lu.assertEquals(fn(true), [[true]])
  lu.assertEquals(fn(nil), [[nil]])
  lu.assertEquals(fn({
    str = "b",
    nbr = 1.1,
    bool = true,
    nn = nil,
  }), [[{
 ["bool"] = true,
 ["nbr"] = 1.1,
 ["str"] = "b",
}]])
lu.assertEquals(fn({
  tbl = {
    str = "b",
    tbl = {
      str = "c",
    },
  },
}), [[{
 ["tbl"] = {
  ["str"] = "b",
  ["tbl"] = {
   ["str"] = "c",
  },
 },
}]])
end

os.exit(lu.run())
