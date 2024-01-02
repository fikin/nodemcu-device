--[[
  Sends HTTP connection response.
]]
local modname = ...

local function isarray(t)
  return type(t) == "table" and #t > 0 and next(t, #t) == nil
end

---decodes http status code to message
---@param code string
---@return string
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

---sends status line to output stream
---@param conn http_conn*
local function sendStatusLine(conn)
  conn.sk:send(string.format("HTTP/1.0 %s %s\r\n", conn.resp.code, codeToMsg(conn.resp.code)))
  coroutine.yield()
end

---sort table by keys
---@param t {[string]:string|number}
---@return fun():string function iternator
local function pairsByKeys(t)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a)
  local i = 0             -- iterator variable
  local iter = function() -- iterator function itself
    i = i + 1
    if a[i] == nil then
      return nil
    else
      return a[i], t[a[i]]
    end
  end
  return iter
end

---sends headers to output stream
---@param conn http_conn*
local function sendHeaders(conn)
  local tbl = conn.resp.headers
  if tbl then
    for k, v in pairsByKeys(tbl) do
      conn.sk:send(string.format("%s: %s\r\n", k, v))
      coroutine.yield()
    end
    conn.resp.headers = nil -- gc
  end
  conn.sk:send("\r\n")
  coroutine.yield()
end

---@param conn http_conn*
---@param str string
local function sendStr(conn, str)
  conn.sk:send(str)
  coroutine.yield()
end

---@param conn http_conn*
---@param fn str_fn
local function sendFn(conn, fn)
  while true do
    local buf = fn()
    if buf == nil then
      break
    end
    sendStr(conn, buf)
  end
end

---@param conn http_conn*
---@param arr string[]
local function sendArr(conn, arr)
  for _, v in ipairs(arr) do
    sendStr(conn, v)
  end
end

---sends body to the remote peer
---@param conn http_conn*
local function sendBody(conn)
  local b = conn.resp.body
  if type(b) == "string" then
    sendStr(conn, b)
  elseif type(b) == "function" then
    sendFn(conn, b)
  elseif isarray(b) then
    ---@cast b string[]
    sendArr(conn, b)
  elseif b then
    sendStr(conn, tostring(b))
  end
end

---serializes http_resp to the connection stream and closes the connectio at the end
---@param conn http_conn*
local function main(conn)
  package.loaded[modname] = nil

  sendStatusLine(conn)
  sendHeaders(conn)
  sendBody(conn)
end

return main
