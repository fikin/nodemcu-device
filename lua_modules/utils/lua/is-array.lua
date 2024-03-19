local modname = ...

---@param t table
---@return boolean true/false if t is an array/isn't an array
local function isArray(t)
    if type(t) ~= "table" then return false end

    --check if all the table keys are numerical and count their number
    local count = 0
    for k, _ in pairs(t) do
        if type(k) ~= "number" then
            return false
        else
            count = count + 1
        end
    end
    --all keys are numerical. now let's see if they are sequential and start with 1
    for i = 1, count do
        --Hint: the VALUE might be "nil", in that case "not t[i]" isn't enough, that's why we check the type
        if not t[i] and type(t[i]) ~= "nil" then
            return false
        end
    end

    -- empty array is not an array
    if #t == 0 then
        return false
    else
        return true
    end
end

---Checks if a table is used as an array. That is: the keys start with one and are sequential numbers
---@param t table
---@return boolean true/false if t is an array/isn't an array
---NOTE: it returns true for an empty table
local function main(t)
    package.loaded[modname] = nil
    return isArray(t)
end

return main
