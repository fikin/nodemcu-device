--[[
  Reads HTTP request into connection object.
]]
local modname = ...

---read from request stream until the pattern is encounred in the buffer 
---@param conn http_conn*
---@param pattern string
---@param maxLen integer
---@param errStatus string
---@return string
local function readUntilPattern(conn, pattern, maxLen, errStatus)
  while true do
    local startPos, endPos = string.find(conn.buffer, pattern)
    if startPos then
      local str = string.sub(conn.buffer, 1, endPos)
      conn.buffer = string.sub(conn.buffer, endPos + 1)
      return str
    elseif #conn.buffer > maxLen then
      error("%s: request is too big (>%d)" & { errStatus, maxLen })
    else
      collectgarbage()
      coroutine.yield()
    end
  end
end

---read max that many bytes from request stream
---@param conn http_conn*
---@param maxLen integer
---@return string
local function readMaxBytes(conn, maxLen)
  while true do
    if #conn.buffer > 0 then
      local str = string.sub(conn.buffer, 1, maxLen)
      conn.buffer = string.sub(conn.buffer, #str + 1)
      return str
    else
      collectgarbage()
      coroutine.yield()
    end
  end
end

---check if method is GET or POST
---@param m string
---@return boolean
local function isValidMethod(m)
  return m == "GET" or m == "POST"
end

---read from request stream given number of bytes
---@param conn http_conn*
---@param bytes integer how many bytes to read before reporting nil (i.e. EOF)
---@return function which is assigned to http_req.body and can be called repeatedly until returns nil on EOF
local function readBodyFn(conn, bytes)
  return function()
    while bytes > 0 do
      local buf = readMaxBytes(conn, 512)
      bytes = bytes - #buf
      return buf
    end
    return nil
  end
end

---parses request line
---@param conn http_conn*
local function parseReqLine(conn)
  local line = readUntilPattern(conn, "\r\n", 512, "414")
  local _, _, method, url = string.find(line, "^([A-Z]+) (.-) HTTP/1.%d\r\n")
  if not isValidMethod(method) or #url == 0 then
    error("405: not an http request %s %s" % { method, url })
  end
  conn.req.method, conn.req.url = method, url
end

---parses all headers as one text blob
---@param conn http_conn*
local function parseHeaders(conn)
  conn.req.headers = readUntilPattern(conn, "\r\n\r\n", 1024, "431")
end

---assign conn.req.body reading function based on content-length header
---@param conn http_conn*
local function setBodyReader(conn)
  local _, _, val = string.find(conn.req.headers, "Content%-Length: (%d+)\r\n")
  if val then
    val = tonumber(val) or 0
    conn.req.bodyLen = val
    conn.req.body = readBodyFn(conn, val)
  else
    conn.req.bodyLen = 0
    conn.req.body = function()
      return nil
    end
  end
end

---parses request header into http_req*
---@param conn http_conn*
local function main(conn)
  package.loaded[modname] = nil

  parseReqLine(conn)
  parseHeaders(conn)
  setBodyReader(conn)
end

return main
