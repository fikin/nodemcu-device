--[[
Safely call a sequence of functions e.g. during boot time.
]]
local modname = ...

---@enum systemctl_status
local stateEnums = { ok = "ok", failed = "failed", inactive = "inactive", running = "running" }

---@class systemctl_service
---@field name string
---@field status systemctl_status
---@field err string|nil
---@field fnc fun()

---@class systemctl_state
---@field status systemctl_status
---@field services systemctl_service[]

local log = require("log")
local node = require("node")

---@type systemctl_state
local db

--init the module, called when "require"-d
local function main()
  ---@type systemctl_state
  local def = {
    status = stateEnums.inactive,
    services = {},
  }
  db = require("state")(modname, def)
end

---add function to be called
---@param name string
---@param fn fun()
local function fnc(name, fn)
  local service = {
    name = name,
    fnc = fn,
    status = stateEnums.inactive,
  }
  table.insert(db.services, service)
end

---start calling the functions
local function start()
  log.info("begining start sequence (%d services) ...", #db.services)
  db.status = stateEnums.running
  local intermState = stateEnums.ok
  for indx, i in ipairs(db.services) do
    i.status = stateEnums.running
    log.info("(%d/%d) : starting '%s' (heap: %d)", indx, #db.services, i.name, node.heap())
    local ok, err = pcall(i.fnc)
    if not ok then
      log.error("(%d/%d) : '%s' failed : %s", indx, #db.services, i.name, err)
      i.err = err
      i.status = stateEnums.failed
      intermState = stateEnums.failed
      if string.find(err, "node%.restart") or string.find(err, "node%.LFS%.reload") then
        -- in case of test cases (nodemcu-lua-mocks), 
        -- node.restart error is raised to simulate interrupt on execution
        error(err)
      end
    else
      i.status = stateEnums.ok
      i.fnc = nil
    end
    collectgarbage("collect")
  end
  db.status = intermState
  log.info("finished with %s.", db.status)

  package.loaded[modname] = nil
end

main()

return {
  start = start,
  fnc = fnc,

  ---register "require(name)" service
  ---@param name string
  require = function(name) fnc(name, function() require(name)() end) end,

  ---get overal status
  ---@return systemctl_status
  status = function() return db.status end,

  ---list services with their states
  ---@return systemctl_service[]
  services = function() return db.services end,

  ---cleanup state
  gc = function() require("state")()[modname] = nil end,
}
