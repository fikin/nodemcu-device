local function round(num)
    local under = math.floor(num)
    local upper = math.floor(num) + 1
    local underV = -(under - num)
    local upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

return round
