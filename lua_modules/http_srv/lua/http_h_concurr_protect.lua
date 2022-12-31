--[[
  HTTP handler protecting againt concurrent calls.
]]
local modname = ...

---protectects endpoint from concurrent calls
---@param maxCnt integer
---@param nextHandler conn_handler_fn
---@return conn_handler_fn
local function main(maxCnt, nextHandler)
  package.loaded[modname] = nil

  return function(conn)
    local state = require("state")(modname)
    local key = conn.req.method .. " " .. conn.req.url
    local ongoing = state[key] or 0
    if ongoing >= maxCnt then
      conn.resp.code = "429"
    else
      state[key] = ongoing + 1 -- inc counter
      table.insert(
        conn.onGcFn,
        function()
          -- decrease counter
          local c = state[key] or 0
          if c > 0 then
            state[key] = c - 1
          end
        end
      )
      nextHandler(conn)
    end
  end
end

return main
