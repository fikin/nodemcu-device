local lu = require("luaunit")
local nodemcu = require("nodemcu")

local function setUp()
    nodemcu.reset()
    package.loaded["scheduler"] = nil -- reset
end

function testDump()
    setUp()

    local fn = require("scheduler")

    lu.assertEquals(fn:dump(), "scheduler dump:")
end

function testSingleThread()
    setUp()

    local fn = require("scheduler")

    lu.assertEquals(fn:dump(), "scheduler dump:")

    local calls = 0
    local function aa(...)
        print("WWW start")
        lu.assertEquals(table.pack(...), { 1, 2, n = 2 })
        for i = 1, 2 do
            calls = calls + 1
            print("WWW ", i)
            fn:yield(calls)
        end
        print("WWW end")
    end

    fn:spawn(aa, 1, 1, 2)
    lu.assertStrContains(fn:dump(), "scheduler dump:\n1 : thread")
    lu.assertEquals(calls, 0)
    fn:pulse(1) -- WWW start
    lu.assertEquals(calls, 1)
    fn:pulse(1) -- WWW 1
    lu.assertEquals(calls, 2)
    fn:pulse(1) -- WWW 2
    lu.assertEquals(calls, 2)
    fn:pulse(1) -- WWW end
    lu.assertEquals(calls, 2)
    lu.assertEquals(fn:dump(), "scheduler dump:")
end

function testPassingSignalArgs()
    setUp()

    local fn = require("scheduler")

    lu.assertEquals(fn:dump(), "scheduler dump:")

    local rec = {}
    fn:spawn(function()
        table.insert(rec, 1)
        local args = table.pack(fn:wait(11))
        table.insert(rec, args)
    end)
    fn:pulse(10)
    fn:signal(11, 2, 3)
    fn:pulse(10)
    lu.assertEquals(rec, { 1, { 2, 3, n = 2 } })
end

function testWaitOrTimeout()
    setUp()

    local fn = require("scheduler")

    lu.assertEquals(fn:dump(), "scheduler dump:")

    local rec = {}
    fn:spawn(function()
        table.insert(rec, 1)
        table.insert(rec, table.pack(fn:waitOrTimeout(11, 5)))
        table.insert(rec, table.pack(fn:waitOrTimeout(12, 5, { 4, 5 })))
    end)
    fn:pulse(10)
    fn:signal(11, 2, 3)
    fn:pulse(10)
    fn:pulse(10)
    lu.assertEquals(rec, { 1, { 2, 3, n = 2 }, { 4, 5, n = 2 } })
end

os.exit(lu.run())
