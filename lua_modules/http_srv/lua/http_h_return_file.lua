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
    conn.resp.body = function()
      local buf = fd:read(256)
      if buf then
        return buf
      else
        fd:close()
        return nil
      end
    end
    table.insert(
      conn.onGcFn,
      function()
        fd:close() -- just in case someone closes connection before reading is over
      end
    )
  else
    error("404: file to read not found %s" % fName)
  end
end

return main
