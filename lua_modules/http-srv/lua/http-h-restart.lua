--[[
  HTTP handler, restarting the device at end of request, if it was ok.
]]
local modname = ...

---callback at connection gc time
---if wasOk is true, device will restart
---@param hasErr boolean
local function restartIfOk(hasErr)
  if hasErr then
    require("log").info("user requested node restart but there was connection error, aborting request")
  else
    require("log").info("user requested node restart, scheduling one in 300ms ...")
    local tmr = require("tmr")
    local t = tmr.create()
    t:alarm(300, tmr.ALARM_SINGLE, function(_)
      require("node").restart()
    end)
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
