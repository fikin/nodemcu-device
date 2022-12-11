--[[
  Sends HTTP connection response.
]]
local modname = ...

local function codeToMsg(code)
  local codes = {
    ["200"] = "OK",
    ["301"] = "Moved Permanently",
    ["400"] = "Bad Request",
    ["401"] = "Unauthorized",
    ["404"] = "Not Found",
    ["405"] = "Method Not Allowed",
    ["414"] = "Request-URI Too Long",
    ["429"] = "Too Many Requests",
    ["431"] = "Request Header Fields Too Large",
    ["500"] = "Internal Server Error"
  }
  return codes[code] or code
end

local function sendStatusLine(conn)
  conn.sk:send("HTTP/1.0 %s %s\r\n" % {conn.resp.code, codeToMsg(conn.resp.code)})
  coroutine.yield()
end

local function sendHeaders(conn)
  if conn.resp.headers then
    for k, v in pairs(conn.resp.headers) do
      conn.sk:send("%s: %s\r\n" % {k, v})
      coroutine.yield()
    end
    conn.resp.headers = nil -- gc
  end
  conn.sk:send("\r\n")
  coroutine.yield()
end

local function sendBody(conn)
  if type(conn.resp.body) == "string" then
    conn.sk:send(conn.resp.body)
    coroutine.yield()
  elseif type(conn.resp.body) == "function" then
    while true do
      local buf = conn.resp.body()
      if buf == nil then
        break
      end
      conn.sk:send(buf)
      coroutine.yield()
    end
  elseif type(conn.resp.body) == "table" then
    for _, v in ipairs(conn.resp.body) do
      conn.sk:send(v)
      coroutine.yield()
    end
  elseif conn.resp.body then
    conn.sk:send(tostring(conn.resp.body))
    coroutine.yield()
  end
end

local function main(conn)
  package.loaded[modname] = nil

  sendStatusLine(conn)
  sendHeaders(conn)
  sendBody(conn)

  conn.sk:close()
end

return main
