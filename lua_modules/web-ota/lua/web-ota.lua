--[[
  HTTP web routes for SW upgrade OTA (over the air).

  Usage:
    Start upgrade by doing "POST /ota/<file>" for all factory files.
    LFS code is special file called "LFS.img".
    Once all upload is over, call "POST /ota?restart" to trigger upgrade.

  The interface is authorized with realm "Upgrade OTA", provided in device setttings.
]]
local modname = ...

---reads sw_version and sends it back to caller
---@param conn http_conn*
local function getSwVersion(conn)
  local data = require("get-sw-version")()
  require("http-h-send-json")(conn, data)
end

---register OTA rest api http routes
local function main()
  package.loaded[modname] = nil

  -- OTA credentials
  local adminCred = require("device-settings")(modname)

  local r = require("http-routes")

  -- OTA portal
  r.setPath(
    "GET",
    "/ota?version",
    function(conn)
      require("http-h-concurr-protect")(1, require("http-h-auth")(adminCred, getSwVersion))(conn)
    end
  )
  r.setPath(
    "POST",
    "/ota?restart",
    function(conn)
      require("http-h-concurr-protect")(1,
        require("http-h-auth")(adminCred, require("http-h-restart")(require("http-h-ok"))))(conn)
    end
  )
  r.setMatchPath(
    "POST",
    "/ota/.+",
    function(conn)
      require("http-h-concurr-protect")(
        1,
        require("http-h-auth")(adminCred, require("http-h-save-file-bak")(true, require("http-h-save-file")))
      )(conn)
    end
  )
end

return main
