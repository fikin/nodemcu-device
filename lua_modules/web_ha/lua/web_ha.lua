--[[
  Setup web rest endpoints for HomeAssistant integration.

  This is the enabler functionalty, setting up NodeMCU-Device platform endpoints.

  Content of what actual HA entities this devices exports are defined via:
    require("web_ha_entity").setSpec()
]]
local modname = ...

---returns HA DataInfo structure
---@param conn any
local function getInfo(conn)
  local data = {
    manufacturer = "fikin",
    name = require("wifi").sta.gethostname(),
    model = "WeMos D1 mini",
    swVersion = require("get_sw_version").version,
    hwVersion = "1.0.0"
  }
  require("http_h_send_json")(conn, data)
end

---copy the table.
---if table key is a function, it evaluates it and includes its result in the copy.
---@param entitiesTbl any
---@return table
local function copyTable(entitiesTbl)
  -- combine all registered entities into single json obj
  local data = {}
  for k, v in pairs(entitiesTbl) do
    if type(v) == "function" then
      v = v()
    end
    data[k] = v
  end
  return data
end

---creates table out of all entitiesTbl and sends it via conn
---@param conn table http_conn* is HA request
---@param entitiesTbl web_ha_entity*
local function sendEntities(conn, entitiesTbl)
  -- combine all registered entities into single json obj
  local data = copyTable(entitiesTbl)
  require("http_h_send_json")(conn, data)
end

---returns registered HA Entities
---@return web_ha_entity*
local function getHaEntities()
  return require("state")("web_ha_entity")
end

local function getSpec(conn)
  sendEntities(conn, getHaEntities().specTypes)
end

local function getData(conn)
  sendEntities(conn, getHaEntities().data)
end

local function setData(conn)
  local data = require("http_h_read_json")(conn)
  for k, v in pairs(data) do
    local fn = getHaEntities().set[k]
    if fn and type(fn) == "function" then
      fn(v)
    else
      error("setting %s is not possible, there is no handler for it" % k)
    end
  end
end

local function main()
  package.loaded[modname] = nil

  -- credentials
  local adminCred = require("device_settings")(modname)

  local r = require("http_routes")

  -- Rest endpoints
  r.setPath(
    "GET",
    "/api/ha/info",
    function(conn)
      require("http_h_concurr_protect")(1, require("http_h_auth")(adminCred, getInfo))(conn)
    end
  )
  r.setPath(
    "GET",
    "/api/ha/spec",
    function(conn)
      require("http_h_concurr_protect")(1, require("http_h_auth")(adminCred, getSpec))(conn)
    end
  )
  r.setPath(
    "GET",
    "/api/ha/data",
    function(conn)
      require("http_h_concurr_protect")(1, require("http_h_auth")(adminCred, getData))(conn)
    end
  )
  r.setPath(
    "POST",
    "/api/ha/data",
    function(conn)
      require("http_h_concurr_protect")(1, require("http_h_auth")(adminCred, setData))(conn)
    end
  )
end

return main
