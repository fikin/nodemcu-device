--[[
  Infrastructure initializer, to be called right after NodeMCU boots up.

  It prints SPIFFS and LFS memory regions. Needed for preparing LFS images.
  
  It initializes LFS.

Depends on: rtctime, node, _reloadLFS, log
]] --
local modname = ...

local function main()
  print("##### ", modname, "START")

  -- a simpleton logger, until real implementation comes via LSF
  local log = {}
  log.info = function(...)
    print("[INFO]", ...)
  end
  log.error = function(...)
    print("[ERROR]", ...)
  end
  log.audit = function(...)
    print("[AUDIT]", ...)
  end
  log.json = function(...)
    print(...)
  end
  package.loaded["log"] = log -- fake "require" until LFS is brought in

  do
    -- initial time seed until net connectivity kicks in
    log.info("RTC time set to Unix epoc start")
    require("rtctime").set(0, 0)
    package.loaded["rtctime"] = nil -- gc
  end

  -- print partitions table (spiffs, lfs)
  do
    local tbl = node.getpartitiontable()
    log.info("The LFS addr is " .. tbl.lfs_addr)
    log.info("The LFS size is " .. tbl.lfs_size)
    log.info("The SPIFFS addr is " .. tbl.spiffs_addr)
    log.info("The SPIFFS size is " .. tbl.spiffs_size)
    local s, p = {}, tbl
    for _, k in ipairs {"lfs_addr", "lfs_size", "spiffs_addr", "spiffs_size"} do
      s[#s + 1] = "%s = 0x%06x" % {k, p[k]}
    end
    log.info("{ %s }" % table.concat(s, ", "))
  end

  do
    -- LFS reload automatically if there is LFS.img in SPIFFS
    require("_reloadLFS")()
  end

  -- LFS print modules, if any
  do
    log.info("LFS modules are:")
    local tbl = node.LFS.list()
    if tbl == nil then
      log.info("  <LFS not loaded yet>")
    else
      for k, v in pairs(tbl) do
        log.info("  ", k, v)
      end
    end
  end

  -- calling LFS _init(), if present
  do
    local fn = node.LFS.get("_init")
    if fn then
      log.info("LFS._init loading ...")
      fn()
      -- clear the simpleton "logger", next user will load it from LFS
      package.loaded["log"] = nil
    end
  end

  print("##### ", modname, "END")

  package.loaded[modname] = nil -- gc
end

return main
