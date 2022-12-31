--[[
  Run at the end to gc all resources related to a single connection.

  Accepts a boolean flag indicating if the whole processing before has had any error or not.
]]
local modname = ...

---it frees all connection resources
---@param conn http_conn*
---@param hasErr boolean
local function main(conn, hasErr)
  package.loaded[modname] = nil

  if conn.sk then
    pcall(
      function()
        conn.sk:close() -- in any case
      end
    )

    for _, v in ipairs({"connection", "reconnection", "disconnection", "receive", "sent"}) do
      conn.sk:on(v, nil) -- clear callbacks
    end
    conn.sk = nil
  end

  conn.buffer = nil
  conn.con = nil

  if conn.req then
    conn.req.body = nil
    conn.req = nil
  end

  if conn.resp then
    conn.resp.headers = nil
    conn.resp.body = nil
    conn.resp = nil
  end

  if conn.onGcFn then
    for _, v in ipairs(conn.onGcFn) do
      local ok, err = pcall(v, hasErr) -- cleanup callbacks
      if not ok then
        require("log").error("cleanup connection", err)
      end
    end
    conn.onGcFn = nil
  end

  collectgarbage()
  collectgarbage()
end

return main
