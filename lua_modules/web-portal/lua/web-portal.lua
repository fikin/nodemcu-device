--[[
  Configures Wifi portal web server.

  To be called by bootprotect init sequence which starts web server.
]]
local modname = ...

---register Wifi portal rest apis as http routes
local function main()
  package.loaded[modname] = nil

  -- portal credentials
  local adminCred = require("device-settings")(modname)

  local r = require("http-routes")

  local function returnFile(conn)
    require("http-h-concurr-protect")(1, require("http-h-auth")(adminCred, require("http-h-return-file")))(conn)
  end

  local function saveFile(conn)
    require("http-h-concurr-protect")(
      1,
      require("http-h-auth")(
        adminCred,
        require("http-h-restart")(require("http-h-save-file-bak")(true, require("http-h-save-file")))
      )
    )(conn)
  end

  -- Wifi config portal

  r.setPath(
    "GET",
    "/",
    function(conn)
      conn.req.url = "/wifi-portal.html" -- serve it under /
      returnFile(conn)
    end
  )
  r.setPath("GET", "/wifi-portal.js", returnFile)
  r.setPath("GET", "/wifi-portal.css", returnFile)
  r.setPath("GET", "/device-settings.json", returnFile)
  r.setPath("POST", "/device-settings.json", saveFile)
end

return main
