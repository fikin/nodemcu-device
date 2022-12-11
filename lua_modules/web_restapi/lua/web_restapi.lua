--[[
  HTTP web routes for Rest API.

  Usage:
    GET /api/status returns application/json with status of the device.
    POST /api/status is accepting settings to apply to the device

  The interface is authorized with realm "Rest API", provided in device setttings.
]]
local modname = ...

local sjson = require("sjson")

local function getState(settingsField)
  return function(conn)
    local txt = sjson.encode(require("state")(settingsField))
    conn.resp.code = "200"
    conn.resp.headers["Content-Type"] = "application/json"
    conn.resp.headers["Content-Length"] = #txt
    conn.resp.body = txt
  end
end

local function readObject(conn)
  local dec = sjson.decoder()
  while true do
    local str = conn.req.body()
    if not str then
      break
    end
    dec:write(str)
  end
  return dec:result()
end

local function setState(settingsField)
  return function(conn)
    local tgt = readObject(conn)

    conn.resp.code = "200"
    
    -- persist in settingsField inside device-settings.json
    local builder = require("factory_settings")
    builder.mergeTblInto(settingsField .. ".target", tgt)
    builder.done()

    -- update RestApi target state
    require("state")(settingsField).target = tgt
  end
end

local function main(srv, settingsField)
  package.loaded[modname] = nil

  -- Rest credentials
  local adminCred = require("device_settings").restApi

  -- OTA portal
  srv.routes["GET /api/status"] = function(conn)
    require("http_h_concurr_protect")(1, require("http_h_auth")(adminCred, getState(settingsField)))(conn)
  end
  srv.routes["POST /api/status"] = function(conn)
    require("http_h_concurr_protect")(1, require("http_h_auth")(adminCred, setState(settingsField)))(conn)
  end

  return srv
end

return main
