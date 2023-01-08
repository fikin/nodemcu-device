--[[
    Substact content present in one table from another table.
]]
local modname = ...

local function isarray(t)
    return #t > 0 and next(t, #t) == nil
end

local function countKeys(tbl)
    local i = 0
    for _, _ in pairs(tbl) do
        i = i + 1
    end
    return i
end

local function subsTbls(from, subs)
    if from == subs then return true; end
    if type(subs) == "table" then
        if isarray(subs) then
            local removeCnt = 0
            for k, v in ipairs(subs) do
                if subsTbls(from[k - removeCnt], v) then
                    table.remove(from, k - removeCnt)
                    removeCnt = removeCnt + 1
                end
            end
            return #from == 0
        else
            for k, v in pairs(subs) do
                if subsTbls(from[k], v) then
                    from[k] = nil
                end
            end
            return countKeys(from) == 0
        end
    end
    return false
end

---from "from" is removed all content, present also in "subs"
---@param from table
---@param subs table
local function main(from, subs)
    package.loaded[modname] = nil
    subsTbls(from, subs)
end

return main
