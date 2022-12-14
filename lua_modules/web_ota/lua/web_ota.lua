--[[
  HTTP web routes for SW upgrade OTA (over the air).

  Usage:
    Start upgrade by doing "POST /ota/<file>" for all factory files.
    LFS code is special file called "LFS.img".
    Once all upload is over, call "POST /ota?restart" to trigger upgrade.

  The interface is authorized with realm "Upgrade OTA", provided in device setttings.
]]
local modname = ...

local function getSwVersion(conn)
  local data = require("get_sw_version")
  require("http_h_send_json")(conn, data)
end

local function main(srv)
  package.loaded[modname] = nil

  -- OTA credentials
  local adminCred = require("device_settings", modname)

  local r = require("http_routes")

  -- OTA portal
  r.setPath(
    "GET",
    "/ota?version",
    function(conn)
      require("http_h_concurr_protect")(1, require("http_h_auth")(adminCred, getSwVersion))(conn)
    end
  )
  r.setPath(
    "POST",
    "/ota?restart",
    function(conn)
      require("http_h_concurr_protect")(1, require("http_h_auth")(adminCred, require("http_h_restart")()))(conn)
    end
  )
  r.setMatchPath(
    "POST",
    "/ota/.+",
    function(conn)
      require("http_h_concurr_protect")(
        1,
        require("http_h_auth")(adminCred, require("http_h_save_file_bak", true)(require("http_h_save_file")))
      )(conn)
    end
  )

  return srv
end

return main
