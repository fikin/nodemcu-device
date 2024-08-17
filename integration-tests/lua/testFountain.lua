local lu = require("luaunit")
local nodemcu = require("nodemcu")

local bootstrapSwLua = "bootstrap-sw.lua"

local function copyFileToSPIFFS(from, to)
  local openFileFn = require("file_obj")
  local f1, _ = openFileFn(from, "r")
  assert(f1)
  local f2, _ = openFileFn(nodemcu.fileLoc(to), "w")
  assert(f2)
  f2:write(f1:read(1024 * 1024))
  f1:close()
  f2:close()
end

local function setupBeforeAll()
  -- set boot delay 0
  _G["NODEMCU_NO_BOOT_DELAY"] = true
  -- setup systemctl bootloader
  _G["BOOTPROTECT"] = "systemctl"
  -- copy test bootstrap-sw.lua to SPIFFS
  -- copyFileToSPIFFS("fountain-bootstrap-sw.lua", bootstrapSwLua)
  file.remove(bootstrapSwLua)
  lu.assertIsTrue(file.exists("fountain-" .. bootstrapSwLua))
  lu.assertIsTrue(file.rename("fountain-" .. bootstrapSwLua, bootstrapSwLua))
end

local function setup()
  nodemcu.reset()
  -- cleanup loaded modules
  for _, i in ipairs({"init", "state", "systemctl"}) do
    package.loaded[i] = nil
  end
end

local function assertLFSReboot()
  setup()
  lu.assertIsFalse(file.exists("LFS.img.PANIC.txt"))
  lu.assertIsTrue(file.exists("LFS.img"))
  local ok, err = pcall(require, "init")
  lu.assertIsFalse(ok)
  lu.assertStrContains(err, "node.LFS.reload")
  -- simulate node.LFS.reload removal of image file
  file.remove("LFS.img")
end

local function assertBootstrapReboot()
  setup()
  lu.assertIsTrue(file.exists(bootstrapSwLua))
  local ok, err = pcall(require, "init")
  lu.assertIsFalse(ok)
  lu.assertStrContains(err, "node.restart")
  lu.assertIsFalse(file.exists("boostsrap-sw.lua"))
end

local function assertDeviceUp()
  setup()
  require("init")
  lu.assertIsNil(_G["init"])
  lu.assertEquals(require("systemctl").status(), "ok")
  require("systemctl").gc()
end

function testOk()
  nodemcu.reset()

  setupBeforeAll()

  assertLFSReboot()
  assertBootstrapReboot()
  assertDeviceUp()
  -- assertWaterLevelLow()
  -- raiseWaterLevel()
  -- assertWaterLevelHigh()
end

os.exit(lu.run())
