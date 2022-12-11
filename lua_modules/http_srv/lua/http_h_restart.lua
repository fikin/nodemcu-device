--[[
  HTTP handler, restarting the device at end of request, if it was ok.
]]
local modname = ...

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
