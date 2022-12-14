--[[
  Reloads "LFS.img" file into LFS.

  After reloading (reboot after flashing) removes the file from SPIFFS.

  In case of flashing error, it creates "LFS.img.PANIC.txt" with boot error (or flashing error).

  Depends on: node, file, rtcmem, log
  
  It uses rtcmem value 17 to track if image was loaded ok or is failing.
]] --

local rtcMem = 17
local panicFName = "LFS.img.PANIC.txt"
local lfsImgFName = "LFS.img"

local modname = ...
local log, file, rtcmem, node = require("log"), require("file"), require("rtcmem"), require("node")

local function imgCleanup()
  file.remove("LFS.img")
  rtcmem.write32(rtcMem, 0)
end

local function imgSaveErr(errMsg)
  log.error(modname, "reloading failed : %s ..." % {lfsImgFName, errMsg})
  file.remove(panicFName)
  file.putcontents(panicFName, errMsg)
end

local function imgDoReload()
  log.info(modname, "reloading %s ..." % lfsImgFName)
  file.remove(panicFName)
  rtcmem.write32(rtcMem, 1)
  local err = node.LFS.reload(lfsImgFName)
  if err then
    imgSaveErr(err)
    imgCleanup()
  end
end

local function isRebootAfterReload()
  local rawcode, reason = node.bootreason()
  return rtcmem.read32(rtcMem) == 1 and rawcode == 2 and reason == 4
end

local function postReloadActions()
  log.info(modname, "post reboot actions ...")
  local _, _, exccause = node.bootreason()
  if exccause then
    imgSaveErr(table.concat({node.bootreason()}, ", "))
  end
  imgCleanup()
end

local function main()
  if file.exists(lfsImgFName) then
    if isRebootAfterReload() then
      postReloadActions()
    else
      imgDoReload()
    end
  else
    log.info(modname, "nothing to do, %s is missing" % lfsImgFName)
  end
  package.loaded[modname] = nil -- gc
end

return main
