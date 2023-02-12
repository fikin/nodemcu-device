--[[
    Substact content present in one table from another table.
]]
local modname = ...

local isArray = require("is-array")

local function countKeys(tbl)
    local i = 0
    for _, _ in pairs(tbl) do
        i = i + 1
    end
    return i
end

local function subsTbls(from, subs)
    local function subTbl(fr, su)
        for k, v in pairs(su) do
            if subsTbls(fr[k], v) then
                fr[k] = nil
            end
        end
        return countKeys(fr) == 0
    end

    local function subArr(fr, su)
        if #fr ~= #su then return false; end
        -- check if all substract-array items are present in from-array
        local sameCnt = 0
        for k, v in ipairs(su) do
            if subsTbls(fr[k], v) then
                sameCnt = sameCnt + 1
            end
        end
        -- clear from-array only if array is identical with substract one
        if #fr == sameCnt then
            for k = #fr, 1, -1 do table.remove(fr, k); end
            return true
        end
        return false
    end

    local function subAny(fr, su)
        if fr == su then return true; end
        if type(su) == "table" then
            if isArray(su) then
                return subArr(fr, su)
            else
                return subTbl(fr, su)
            end
        end
        return false
    end

    return subAny(from, subs)
end

---from "from" is removed all content, present also in "subs"
---@param from table
---@param subs table
local function main(from, subs)
    package.loaded[modname] = nil
    subsTbls(from, subs)
end

return main
