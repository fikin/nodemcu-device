local lu = require("luaunit")
local nodemcu = require("nodemcu")

function testInit()
    nodemcu.reset()

    require("init")
    nodemcu.advanceTime(1000)
end

os.exit(lu.run())
