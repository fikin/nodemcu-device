---@class deque_obj
---@field _data any[]
---@field _maxlen number
local M = {}
M.__index = M

---append element to the deque
---@param self deque_obj
---@param val any
M.append = function(self, val)
    while #self._data >= self._maxlen do
        table.remove(self._data, 1)
    end
    table.insert(self._data, val)
end

---look the value of first element in the deque
---@param self deque_obj
---@return any
M.peekFirst = function(self)
    return self._data[1]
end

---lists items in the deque
---@param self deque_obj
---@return any[]
M.peekItems = function(self)
    return self._data
end

---@param self deque_obj
---@return number
M.maxLen = function(self)
    return self._maxlen
end

---@param self deque_obj
---@return integer
M.len = function(self)
    return #self._data
end

---clear internal state
---@param self deque_obj
M.clear = function(self)
    self._data = {}
end

---get data at position in the queue
---@param self deque_obj
---@param pos integer position in the deque, 1 is first item, =len() is the last
---@return any
M.itemAt = function(self, pos)
    local pp = pos
    if pos < 0 then
        pos = self:len() + pos + 1
    end
    assert(pos > 0)
    assert(pos <= self:len(), string.format("pos=%d , len=%d", pp, self:len()))
    return self._data[pos]
end

---instantiate new deque object
---@param maxlen integer max deque size
---@param defValue? any object to initially populate all elements with, can be nil
---@return deque_obj
local function main(maxlen, defValue)
    local o = setmetatable({
        _data = {},
        _maxlen = maxlen,
    }, M)
    for i = 1, maxlen do
        o._data[i] = defValue
    end
    return o
end

return main
