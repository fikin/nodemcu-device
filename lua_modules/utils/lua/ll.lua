--[[
    listing file system content
]]
local modname = ...

---right-side padding string
---@param str string
---@param len integer
---@param char string
---@return string
local function rpad(str, len, char)
    if char == nil then char = ' ' end
    return str .. string.rep(char, len - #str)
end

---return table kets
---@param tbl table[string:any]
---@return string[]
local function getKeys(tbl)
    local ret = {}
    for k, _ in pairs(tbl) do
        table.insert(ret, k)
    end
    return ret
end

local function prn(name, size)
    print(rpad(name, 25, " "), size)
end

---lists SPIFFS content
---@param fn nil|fun(name:string,size:integer) print function to use or use default
local function main(fn)
    package.loaded[modname] = nil

    local file = require("file")
    local tbl = file.list()
    local lst = getKeys(tbl)
    table.sort(lst)

    fn = fn or prn
    for _, v in pairs(lst) do
        fn(v, tbl[v])
    end
end

return main
