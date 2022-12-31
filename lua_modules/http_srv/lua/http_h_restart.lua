--[[
  HTTP handler, restarting the device at end of request, if it was ok.
]]
local modname = ...

---callback at connection gc time
---if wasOk is true, device will restart
---@param wasOk boolean
local function restartIfOk(wasOk)
  if wasOk then
    local node = require("node")
    node.task.post(
      function()
        node.restart()
      end
    )
  end
end

---triggers device restart after responding with 200
---restart happens on connection gc
---@param nextHandler conn_handler_fn
---@return conn_handler_fn
local function main(nextHandler)
  package.loaded[modname] = nil

  return function(conn)
    if nextHandler then
      nextHandler(conn)
    else
      conn.resp.code = "200"
    end
    table.insert(conn.onGcFn, restartIfOk)
  end
end

return main
