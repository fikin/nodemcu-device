--[[
  HTTP web routes for SW upgrade OTA (over the air).

  Usage:
    Start upgrade by doing "POST /ota/<file>" for all factory files.
    LFS code is special file called "LFS.img".
    Once all upload is over, call "POST /ota?restart" to trigger upgrade.

  The interface is authorized with realm "Upgrade OTA", provided in device setttings.
]]
local modname = ...

---@param conn http_conn*
---@param method string
---@param pathPattern string
---@return boolean match
local function isPathMatch(conn, method, pathPattern)
  return string.find(conn.req.url, pathPattern) ~= nil
end

---@param conn http_conn*
---@param method string
---@param path string
---@return boolean
local function isPath(conn, method, path)
  return method == conn.req.method and path == conn.req.url
end

---read settings, they are cached in state for faster parsing
---@return http_h_auth
local function getSettings()
  local state = require("state")(modname, nil, true)
  if state == nil then
    local cfg = require("device-settings")(modname)
    state = require("state")(modname, cfg)
  end
  return state
end

---checks the authentication and if ok handles it in nextFn
---@param nextFn conn_handler_fn
---@param conn http_conn*
---@return boolean
local function checkAuth(nextFn, conn)
  -- portal credentials
  ---@type http_h_auth
  local adminCred = getSettings()
  if require("http-authorize")(conn, adminCred) then
    nextFn(conn)
  end
  return true
end

---reads sw_version and sends it back to caller
---@param conn http_conn*
local function handleSwVersion(conn)
  local data = require("get-sw-version")()
  require("http-h-send-json")(conn, data)
end

---@param conn http_conn*
local function handleRestart(conn)
  require("http-h-restart")(require("http-h-ok"))(conn)
end

---@param conn http_conn*
local function handleSaveFile(conn)
  require("http-h-save-file-bak")(true, require("http-h-save-file"))(conn)
end

---handle http request if it is OTA rest apis related
---@param conn http_conn*
---@return boolean
local function main(conn)
  package.loaded[modname] = nil

  if isPath(conn, "GET", "/ota?version") then
    return checkAuth(handleSwVersion, conn)
  elseif isPath(conn, "POST", "/ota?restart") then
    return checkAuth(handleRestart, conn)
  elseif isPathMatch(conn, "POST", "/ota/.+") then
    return checkAuth(handleSaveFile, conn)
  else
    return false
  end
end

return main
