--[[
  Reloads "LFS.img" file into LFS.

  After reloading (reboot after flashing) removes the file from SPIFFS.

  In case of flashing error, it creates "LFS.img.PANIC.txt" with boot error (or flashing error).

  Depends on: node, file, rtcmem, log
  
  It uses rtcmem value 17 to track if image was loaded ok or is failing.
]] --
local modname = ...

---rtcmem byte indicating reboot is after flashing LFS.img
---and it is to be removed now
local rtcMem = 17

---file containing reboot error text in case of error
local panicFName = "LFS.img.PANIC.txt"

---flash image file
local lfsImgFName = "LFS.img"

local log, file, rtcmem, node = require("log"), require("file"), require("rtcmem"), require("node")

---reove LFS.img and clear rtcmem flags
---called after falsh attempt on error or success
local function imgCleanup()
  file.remove("LFS.img")
  rtcmem.write32(rtcMem, 0)
end

---create flash error text file
---@param errMsg string
local function imgSaveErr(errMsg)
  log.error(modname, string.format("reloading failed : %s : %s", lfsImgFName, errMsg))
  file.remove(panicFName)
  file.putcontents(panicFName, errMsg)
end

---flash the image file
---node will auto-reboot at end of this function
local function imgDoReload()
  log.info(modname, string.format("reloading %s ...", lfsImgFName))
  file.remove(panicFName)
  rtcmem.write32(rtcMem, 1)
  local err = node.LFS.reload(lfsImgFName)
  if err then
    imgSaveErr(err)
    imgCleanup()
  end
end

---test if current boot is the one after flash reloading
---@return boolean is true if rtcmem flag is set and boot reason is 2 or 4
local function isRebootAfterReload()
  local rawcode, reason = node.bootreason()
  return rtcmem.read32(rtcMem) == 1 and rawcode == 2 and reason == 4
end

---executed at reboot after flash reload to clear files
local function postReloadActions()
  log.info(modname, "post reboot actions ...")
  local _, _, exccause = node.bootreason()
  if exccause then
    imgSaveErr(table.concat({ node.bootreason() }, ", "))
  end
  imgCleanup()
end

---executes flash reload
local function main()
  if file.exists(lfsImgFName) then
    if isRebootAfterReload() then
      postReloadActions()
    else
      imgDoReload()
    end
  else
    log.info(modname, string.format("nothing to do, %s is missing", lfsImgFName))
  end
  package.loaded[modname] = nil -- gc
end

return main
