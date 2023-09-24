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

---reads sw_version and sends it back to caller
---@param conn http_conn*
local function handleSwVersion(conn)
  local data = require("get-sw-version")()
  require("http-h-send-json")(conn, data)
end

---reads "releases" file and sends it back to caller
---@param conn http_conn*
local function handleSwRelease(conn)
  local txt = require("file").getcontents("release")
  conn.resp.code = "200"
  conn.resp.headers["Content-Type"] = "text/plain"
  conn.resp.headers["Content-Length"] = #txt
  conn.resp.headers["Cache-Control"] = "private, no-cache, no-store"
  conn.resp.body = txt
end

---@param conn http_conn*
local function handleRestart(conn)
  require("http-h-restart")(nil)(conn)
end

local function deleteFile(fl)
  local l = require("log")
  local file = require("file")
  if file.exists(fl) then
    l.info("removing %s", fl)
    file.remove(fl)
  end
end

local function renameFile(from, to)
  local l = require("log")
  local file = require("file")
  if file.exists(from) then
    deleteFile(to)
    l.debug("renaming %s to %s", from, to)
    if not file.rename(from, to) then
      l.error("failed to rename %s to %s", from, to)
      return false
    end
  end
  return true
end

---@param conn http_conn*
local function handleSaveFile(conn)
  local fName1 = string.sub(conn.req.url, 2)
  local fName2 = string.sub(conn.req.url, 6)
  local fBak = fName2 .. ".bak"
  local function f()
    deleteFile(fBak)
    if renameFile(fName2, fBak) then
      if renameFile(fName1, fName2) then
        deleteFile(fBak)
      else
        renameFile(fBak, fName2)
      end
    end
  end
  table.insert(conn.onGcFn, f)

  require("http-h-save-file")(conn)
end

---handle http request if it is OTA rest apis related
---@param conn http_conn*
---@return boolean
local function main(conn)
  package.loaded[modname] = nil

  if isPath(conn, "GET", "/ota?version") then
    return checkAuth(handleSwVersion, conn)
  elseif isPath(conn, "GET", "/ota?release") then
    return checkAuth(handleSwRelease, conn)
  elseif isPath(conn, "POST", "/ota?restart") then
    return checkAuth(handleRestart, conn)
  elseif isPathMatch(conn, "POST", "/ota/.+") then
    return checkAuth(handleSaveFile, conn)
  else
    return false
  end
end

return main
