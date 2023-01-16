--[[
  HTTP handler, restarting the device at end of request, if it was ok.
]]
local modname = ...

---callback at connection gc time
---if wasOk is true, device will restart
---@param hasErr boolean
local function restartIfOk(hasErr)
  if hasErr then
    require("log").info("Ignoring node restart request due to failed http call")
  else
    local task = require("node").task
    task.post(task.MEDIUM_PRIORITY, function() node.restart(); end)
  end
end

---triggers device restart after responding with 200
---restart happens on connection gc
---@param nextHandler? conn_handler_fn
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
