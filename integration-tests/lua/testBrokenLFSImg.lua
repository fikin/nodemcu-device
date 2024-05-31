local lu = require("luaunit")
local nodemcu = require("nodemcu")

local file = require("file")
local sjson = require("sjson")

---test that LFS.img is LFS.reload() and error is captured.
---as node.LFS.reload() is not possible to implement currently.

function testInit()
    nodemcu.reset()
    
    --lu.assertIsTrue(file.exists("LFS.img"))
    lu.assertIsFalse(file.exists("LFS.img.PANIC.txt"))
    lu.assertIsTrue(file.exists("LFS.img"))

    -- global var, nodemcu will read it
    NODEMCU_LFS_RELOAD_FAIL = "asked to fail"

    require("init")
    nodemcu.advanceTime(2000)

    lu.assertEquals(file.getcontents("LFS.img.PANIC.txt"), NODEMCU_LFS_RELOAD_FAIL)
    lu.assertIsFalse(file.exists("LFS.img"))

    -- gc global var
    _G["NODEMCU_LFS_RELOAD_FAIL"] = nil
end

os.exit(lu.run())
