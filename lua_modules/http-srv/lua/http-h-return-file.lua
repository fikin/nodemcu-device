--[[
  HTTP handler returning a file.

  It recognizes URL pattern "/<file>".
]]
local modname = ...

---decodes mime types out of file extension
---@param url string
---@return string
local function getMimeType(url)
  for k, v in pairs(
    {
      ["css"] = "text/css",
      ["csv"] = "text/csv",
      ["html"] = "text/html",
      ["js"] = "text/javascript",
      ["json"] = "application/json",
      ["png"] = "image/png",
      ["txt"] = "text/plain"
    }
  ) do
    if string.find(url, ".*%." .. k .. "$") then
      return v
    end
  end
  return "application/octet-stream"
end

---read file content
---@param fd file_obj
---@return str_fn
local function readFileFn(fd)
  return function()
    local buf = fd:read(256)
    if buf then
      return buf
    else
      fd:close()
      return nil
    end
  end
end

---closes the file
---@param fd file_obj
---@return conn_gc_fn
local function closeFileFn(fd)
  return function()
    fd:close()
  end
end

---returns file with given url path
---@param conn http_conn*
local function main(conn)
  package.loaded[modname] = nil

  local file = require("file")

  local fName = string.sub(conn.req.url, 2)

  local fd = file.open(fName, "r")
  if fd then
    conn.resp.code = "200"
    conn.resp.headers["Content-Type"] = getMimeType(conn.req.url)
    conn.resp.headers["Content-Length"] = file.stat(fName).size
    conn.resp.headers["Cache-Control"] = "private, no-cache, no-store"
    conn.resp.body = readFileFn(fd)

    -- just in case if remote would close the connection before reading is over
    table.insert(conn.onGcFn, closeFileFn(fd))
  else
    error("404: file to read not found %s" % fName)
  end
end

return main
