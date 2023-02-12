local lu = require("luaunit")

local fn = require("table-substract")
local sjson = require("sjson")

function testFlatDict()
    local o = { a = 5, b = "aa" }
    fn(o, { a = 5, b = "aa" })
    local txt = sjson.encode(o)
    lu.assertEquals(txt, '[]')
end

function testFlatArr()
    local o = { 1, "aa", 2 }
    fn(o, { 1, "aa", 2 })
    local txt = sjson.encode(o)
    lu.assertEquals(txt, '[]')
end

function testDeep()
    local o = {
        k1 = {
            k2 = { 1, 2, 3 },
            k3 = "bbb"
        },
        k4 = 4
    }
    local o2 = {
        k1 = {
            k2 = { 1, 2, 3 },
            k3 = "bbb"
        },
        k4 = 4
    }
    fn(o, o2)
    local txt = sjson.encode(o)
    lu.assertEquals(txt, '[]')
end

function testDeep2()
    local o = {
        k1 = {
            k2 = { 1, 2, 3 },
            k3 = "bbb"
        },
        k4 = 4
    }
    local o2 = {
        k1 = {
            k2 = { 1, 2 },
            k3 = "bbb"
        },
        k4 = 5,
        k6 = 0,
    }
    fn(o, o2)
    local txt = sjson.encode(o)
    lu.assertEquals(txt, '{"k1":{"k2":[1,2,3]},"k4":4}')
end

function testArray()
    local o = sjson.decode('{"bootsequence":["user-settings","log-start"]}')
    local o2 = sjson.decode('{"bootsequence":["user-settings","log-start","telnet"]}')
    fn(o, o2)
    lu.assertEquals(o, { ["bootsequence"] = { "user-settings", "log-start" } })
end

function testArrayNoDiff()
    local o = sjson.decode('{"bootsequence":["user-settings","log-start"]}')
    local o2 = sjson.decode('{"bootsequence":["user-settings","log-start"]}')
    fn(o, o2)
    lu.assertEquals(o, {})
end

os.exit(lu.run())
