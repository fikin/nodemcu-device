--[[
    listing file system content
]]
local modname = ...

local function prn(name, size)
    print(require("rpad")(name, 25, " "), size)
end

---lists SPIFFS content
---@param fn nil|fun(name:string,size:integer) print function to use or use default
local function main(fn)
    package.loaded[modname] = nil

    require("table-visitor")(require("file").list(), fn or prn)
end

return main
