--[[
  HTTP hander saving a file.

  It recognizes url in the form "/<file>".
]]
local modname = ...

---saves the http stream into a file
---@param readFn fun():string
---@param fd file_obj object
local function saveContent(readFn, fd)
  while true do
    local buf = readFn()
    if buf then
      if not fd:write(buf) then
        fd:close()
        error("500: failed writing to file")
      end
    else
      break
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

---saves file as given url
---@param conn http_conn*
local function main(conn)
  package.loaded[modname] = nil

  local file = require("file")

  local fName = string.sub(conn.req.url, 2)

  local fd = file.open(fName, "w")
  if fd then
    -- just in case if remote would close the connection before reading is over
    table.insert(conn.onGcFn, closeFileFn(fd))

    saveContent(conn.req.body, fd)
    fd:close()
    collectgarbage()
    conn.resp.code = "200"
  else
    error("500: cannot open file for writting: " .. fName)
  end
end

return main
