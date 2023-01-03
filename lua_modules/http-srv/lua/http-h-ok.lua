--[[
  HTTP handler responding 200.
]]
local modname = ...

---respond with 200
---@return conn_handler_fn
local function main()
  package.loaded[modname] = nil

  return function(conn)
    conn.resp.code = "200"
  end
end

return main
