--[[
  Configures Wifi portal web server.

  To be called by bootprotect init sequence which starts web server.
]]
local modname = ...

local function main(srv)
  package.loaded[modname] = nil

  -- portal credentials
  local adminCred = require("device_settings").webPortal

  -- Wifi config portal
  srv.routes["GET /"] = function(conn)
    conn.req.url = "/wifi-portal.html" -- serve it under /
    require("http_h_concurr_protect")(1, require("http_h_auth")(adminCred, require("http_h_return_file")))(conn)
  end
  srv.routes["GET /wifi-portal.js"] = function(conn)
    require("http_h_concurr_protect")(1, require("http_h_auth")(adminCred, require("http_h_return_file")))(conn)
  end
  srv.routes["GET /wifi-portal.css"] = function(conn)
    require("http_h_concurr_protect")(1, require("http_h_auth")(adminCred, require("http_h_return_file")))(conn)
  end
  srv.routes["GET /device-settings.json"] = function(conn)
    require("http_h_concurr_protect")(1, require("http_h_auth")(adminCred, require("http_h_return_file")))(conn)
  end
  srv.routes["POST /device-settings.json"] = function(conn)
    require("http_h_concurr_protect")(
      1,
      require("http_h_auth")(
        adminCred,
        require("http_h_restart")(require("http_h_save_file_bak")(require("http_h_save_file")))
      )
    )(conn)
  end

  return srv
end

return main
