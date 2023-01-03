--
-- File: LFS_dummy_strings.lua
--[[
  luac.cross -f generates a ROM string table which is part of the compiled LFS
  image. This table includes all strings referenced in the loaded modules.

  If you want to preload other string constants, then one way to achieve this is
  to include a dummy module in the LFS that references the strings that you want
  to load. You never need to call this module; it's inclusion in the LFS image is
  enough to add the strings to the ROM table. Your application can use any strings
  in the ROM table without incuring any RAM or Lua Garbage Collector (LGC)
  overhead.

  The local preload example is a useful starting point. However, if you call the
  following code in your application during testing, then this will provide a
  listing of the current RAM string table.

do
  local a=debug.getstrings'RAM'
  for i =1, #a do a[i] = ('%q'):format(a[i]) end
  print ('local preload='..table.concat(a,','))
end

  This will exclude any strings already in the ROM table, so the output is the list
  of putative strings that you should consider adding to LFS ROM table.

---------------------------------------------------------------------------------
]] --

-- luacheck: ignore
local preload = {
  " at line ",
  " expected (to close ",
  " near ",
  " not installed.",
  "%q",
  "'",
  "']",
  "'do'",
  "'end'",
  "(for index)",
  "(for limit)",
  "(for step)",
  "/\n;\n?\n!\n-",
  "192.168.1.1",
  "192.168.1.100",
  "255.255.255.0",
  "<LFS not loaded yet>",
  "=stdin",
  "?.lc",
  "?.lc;?.lua",
  "?.lua",
  "@../local/fs/init.lua",
  "@init.lua",
  "[AUDIT]",
  "[ERROR]",
  "[INFO]",
  "__add",
  "__call",
  "__concat",
  "__div",
  "__eq",
  "__gc",
  "__index",
  "__le",
  "__len",
  "__lt",
  "__mod",
  "__mode",
  "__mul",
  "__name",
  "__newindex",
  "__pow",
  "__sub",
  "__tostring",
  "__unm",
  "_G",
  "_init.lc",
  "_LOADED",
  "_LOADLIB",
  "_PRELOAD",
  "_PROMPT",
  "_PROMPT2",
  "_reloadLFS",
  "_VERSION",
  "admin",
  "AP_PROBEREQRECVED",
  "AP_STACONNECTED",
  "AP_STACONNECTED_",
  "AP_STADISCONNECTED",
  "AUDIT",
  "auth",
  "auto",
  "beacon",
  "BSSID",
  "channel",
  "collectgarbage",
  "cpath",
  "crypto.hash",
  "debug",
  "DEBUG",
  "desireFn",
  "Device Admin",
  "Device Settings",
  "END",
  "end_ch",
  "ERROR",
  "file",
  "file.obj",
  "file.vol",
  "flash",
  "gateway",
  "GET /wifi-portal.html",
  "getpartitiontable",
  "getstrings",
  "hidden",
  "index",
  "INFO",
  "init",
  "ip",
  "ipairs",
  "lastlinedefined",
  "LFS modules are:",
  "LFS._init loading ...",
  "lfs_addr",
  "lfs_size",
  "linedefined",
  "list",
  "loaded",
  "loader",
  "loaders",
  "loadlib",
  "local preload=",
  "Lua 5.3",
  "Lua",
  "LUABOX",
  "MAC",
  "max",
  "module",
  "mqtt.socket",
  "net.tcpserver",
  "net.tcpsocket",
  "net.udpsocket",
  "netmask",
  "newproxy",
  "not enough memory",
  "onerror",
  "package",
  "pairs",
  "path",
  "policy",
  "preload",
  "RAM",
  "rawcode",
  "reason",
  "reload",
  "require",
  "ROM",
  "RSSI",
  "RTC time set to Unix epoc start",
  "save",
  "searchers",
  "searchpath",
  "seeall",
  "set",
  "sjson.decoder",
  "sjson.encoder",
  "source",
  "spiffs_addr",
  "spiffs_size",
  "SSID",
  "STA_AUTHMODE_CHANGE",
  "STA_CONNECTED",
  "STA_DHCP_TIMEOUT",
  "STA_DISCONNECTED",
  "STA_GOT_IP",
  "START",
  "start_ch",
  "stdin",
  "stdout",
  "The LFS addr is ",
  "The LFS size is ",
  "The SPIFFS addr is ",
  "The SPIFFS size is ",
  "tmr.timer",
  "wday",
  "wdclr",
  "what",
  "WIFI_MODE_CHANGED",
  "WIFI_MODE_CHANGED%->",
  "WIFI_MODE_CHANGED->wifi_mgr",
  "WIFI_MODE_CHANGED->wifi_start_ap",
  "WIFI_MODE_CHANGED_",
  "yday",
  "{ %s }"
}
-- require("dummy-strings")() will print the missing strings, you can add to above list.
local modname = ...

return function()
  local a = debug.getstrings("RAM")
  for i = 1, #a do
    a[i] = ("%q"):format(a[i])
  end
  print("local preload=" .. table.concat(a, ","))
  package.loaded[modname] = nil
end
