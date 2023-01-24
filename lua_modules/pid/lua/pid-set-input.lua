--[[
    Assign new Input value
]]
local modname = ...

---@return pid_state
local function getState()
    return require("state")("pid")
end

---assigns PID's input value
---@param input number
local function main(input)
    package.loaded[modname] = nil

    getState().Input = input
end

return main
