--[[
    Assign new Input value
]]
local modname = ...

---@return pid_state
local function getState()
    return require("state")("pid")
end

---reads PID output value
---@return number
local function main()
    package.loaded[modname] = nil

    return getState().Output
end

return main
