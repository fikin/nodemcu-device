--[[
  Reads HTTP request into connection object.
]]
local modname = ...

local function readUntilPattern(conn, pattern, maxLen, errStatus)
  while true do
    local startPos, endPos = string.find(conn.buffer, pattern)
    if startPos then
      local str = string.sub(conn.buffer, 1, endPos)
      conn.buffer = string.sub(conn.buffer, endPos + 1)
      return str
    elseif #conn.buffer > maxLen then
      error("%s: request is too big (>%d)" & {errStatus, maxLen})
    else
      collectgarbage()
      coroutine.yield()
    end
  end
end

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

local function isValidMethod(m)
  return m == "GET" or m == "POST"
end

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

local function parseReqLine(conn)
  local line = readUntilPattern(conn, "\r\n", 512, "414")
  local _, _, method, url = string.find(line, "^([A-Z]+) (.-) HTTP/1.%d\r\n")
  if not isValidMethod(method) or #url == 0 then
    error("405: not an http request %s %s" % {method, url})
  end
  conn.req.method, conn.req.url = method, url
end

local function parseHeaders(conn)
  conn.req.headers = readUntilPattern(conn, "\r\n\r\n", 1024, "431")
end

local function setBodyReader(conn)
  local _, _, val = string.find(conn.req.headers, "Content%-Length: (%d+)\r\n")
  if val then
    val = tonumber(val)
    conn.req.bodyLen = val
    conn.req.body = readBodyFn(conn, val)
  else
    conn.req.bodyLen = 0
    conn.req.body = function()
      return nil
    end
  end
end

local function main(conn)
  package.loaded[modname] = nil

  parseReqLine(conn)
  parseHeaders(conn)
  setBodyReader(conn)
end

return main
