--[[
  Infrastructure initializer, to be called right after NodeMCU boots up.

  It prints SPIFFS and LFS memory regions. Needed for preparing LFS images.

  It initializes LFS.

Depends on: rtctime, node, _reloadLFS
]]
--
local modname = ...

---initialize LFS and require and etc.
local function main()
  print("##### ", modname, "START")

  -- a simpleton logger, until real implementation comes via LSF
  local log = {}
  log.info = function(format, ...)
    print(string.format("[INFO]: " .. format, ...))
  end
  log.error = function(format, ...)
    print(string.format("[ERROR]: " .. format, ...))
  end
  log.audit = function(format, ...)
    print(string.format("[AUDIT]: " .. format, ...))
  end
  log.json = function(...)
    print(...)
  end
  package.loaded["log"] = log -- fake "require" until LFS is brought in

  local node = require("node")

  do
    -- initial time seed until net connectivity kicks in
    log.info("RTC time set to Unix epoc start")
    require("rtctime").set(0, 0)
    package.loaded["rtctime"] = nil -- gc
  end

  -- print partitions table (spiffs, lfs)
  do
    local tbl = node.getpartitiontable()
    log.info("The LFS addr is %d", tbl.lfs_addr)
    log.info("The LFS size is %d", tbl.lfs_size)
    log.info("The SPIFFS addr is %d", tbl.spiffs_addr)
    log.info("The SPIFFS size is %d", tbl.spiffs_size)
    local s, p = {}, tbl
    for _, k in ipairs { "lfs_addr", "lfs_size", "spiffs_addr", "spiffs_size" } do
      s[#s + 1] = string.format("%s = 0x%06x", k, p[k])
    end
    log.info("{ %s }", table.concat(s, ", "))
  end

  do
    -- LFS reload automatically if there is LFS.img in SPIFFS
    -- it reboots device after this point if LFS is updated
    require("_lfs-reload")()
  end

  -- LFS print modules, if any
  do
    log.info("LFS modules are:")
    local tbl = node.LFS.list()
    if tbl == nil then
      log.info("  <LFS not loaded yet>")
    else
      for k, v in pairs(tbl) do
        log.info("  %s %s", k, v)
      end
    end
  end

  -- calling LFS _init(), if present
  do
    local fn = node.LFS.get("_init")
    if fn then
      log.info("LFS._init loading ...")
      fn()
    else
      log.info("<No LFS _init function defined>")
    end
  end

  -- SPIFFS print directory
  do
    log.info("SPIFFS contains:")
    require("ll")(function(name, size)
      log.info("  %6d %s", size, name)
    end)
  end

  -- clear the simpleton "logger", next user will load it from LFS
  package.loaded["log"] = nil

  print("##### ", modname, "END")

  package.loaded[modname] = nil -- gc
end

return main
