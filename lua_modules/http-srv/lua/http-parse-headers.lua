local modname = ...

local strSplit = require("str-split")

---split header line
---@param line string
---@return string|nil key
---@return string value
local function splitHeaderLine(line)
    local sP, eP = string.find(line, ": ")
    if sP then
        return string.sub(line, 1, sP - 1), string.sub(line, eP + 1)
    elseif string.sub(line, 1, 1) == " " then
        return nil, string.sub(line, 2)
    else
        error("400: wrong http header line: " .. line)
    end
end

---parse list of header lines
---@param lst string[]
---@return {[string]:string} headers as table key=value
local function parseList(lst)
    local tbl = {}

    local lastKey
    for _, line in ipairs(lst) do
        if #line > 0 then
            local key, value = splitHeaderLine(line)
            if key then
                tbl[key] = value
                lastKey = key
            elseif value then
                tbl[lastKey] = tbl[lastKey] .. key
            end
        end
    end

    return tbl
end

---parses block of text, representing HTTP headers
---into key=value table where each key is header name
---and value is remainder of the line.
---@param text string of new-line delimited text
---@return {[string]:string}
local function main(text)
    package.loaded[modname] = nil

    local lst = strSplit(text, "\r\n")

    return parseList(lst)
end

return main
