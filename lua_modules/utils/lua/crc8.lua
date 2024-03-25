local modname = ...

---convert string to ascii array
---@param str string
---@return integer[]
local function strToAsciiArr(str)
    local arr = {}
    for i = 1, #str do
        table.insert(arr, string.byte(str, i))
    end
    return arr
end

---calculate crc8 for given array
---@param t integer[]
---@return integer
local function crc8(t)
    local c = 0
    for _, b in ipairs(t) do
        for i = 0, 7 do
            c = c >> 1 ~ ((c ~ b >> i) & 1) * 0x8C
        end
    end
    return c
end

---calculate crc8 for given array
---@param t nil|integer[]|string
---@return integer
local function main(t)
    package.loaded[modname] = nil

    if t == nil then
        return 0
    elseif type(t) == "string" then
        return crc8(strToAsciiArr(t))
    else
        return crc8(t)
    end
end

return main
