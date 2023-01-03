local modname = ...

local sjson = require("sjson")

local jsonNull = sjson.decode('{ "a": null  }').a

local function isarray(t)
    return #t > 0 and next(t, #t) == nil
end

local function removeEmptyKeys(obj)
    if obj == jsonNull then
        return nil
    end
    if type(obj) == "table" then
        for k, v in pairs(obj) do
            if v == jsonNull then
                obj[k] = removeEmptyKeys(v)
            end
        end
        if isarray(obj) then
            for i, v in ipairs(obj) do
                table.remove(obj, i)
                table.insert(obj, i, removeEmptyKeys(v))
            end
        end
    end
    return obj
end

---turn text to object and remove null keys
---@param txt string
---@return table
local function toJson(txt)
    local obj = sjson.decode(txt)
    removeEmptyKeys(obj)
    return obj
end

---string to json with removal of null keys
---@param txt string
---@return table
local function main(txt)
    package.loaded[modname] = nil
    return toJson(txt)
end

return main
