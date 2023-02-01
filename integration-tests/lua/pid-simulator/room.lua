---@class room_obj
--- specific heat capacity of air: c = 0.7 kJ / kg * K
---@field SPECIFIC_HEAT_CAP_AIR number
--- thermal conductivity of steel: lambda = 15 W / m * K
---@field THERMAL_CONDUCTIVITY_WALLS number
--- room's temperature
---@field _temp number
--- room's surface area
---@field _surface number
---room's air mass
---@field _mass number
local M = {}
M.__index = M

---@return room_obj
local function newInst()
    return {
        --- specific heat capacity of air: c = 0.7 kJ / kg * K
        ---@type number
        SPECIFIC_HEAT_CAP_AIR = 0.7,

        --- thermal conductivity of walls: lambda = 1.2 W / m * K
        --- this value is basically 220mm solid bricks wall
        ---@type number
        THERMAL_CONDUCTIVITY_WALLS = 1.2,

        --- room's temperature
        ---@type number
        _temp = 0,
        --- room's surface area
        ---@type number
        _surface = 0,
        ---room's air mass
        ---@type number
        _mass = 0,
    }
end

---calculate temperature change for given duration and applied power
---@param self room_obj
---@param power number
---@param duration number
---@return number
local function _get_deltaT(self, power, duration)
    -- P = Q / t
    -- Q = c * m * delta T
    -- => delta(T) = (P * t) / (c * m)
    return ((power * duration) / (self.SPECIFIC_HEAT_CAP_AIR * self._mass))
end

---get current room temperature
---@param self room_obj
---@return number
M.temperature = function(self)
    return self._temp
end

---Heat the room's content.
---@param self room_obj
---@param power number The power in kW.
---@param duration number The duration in seconds.
---@param efficiency? number The efficiency as number between 0 and 1.
---@return number
M.heat = function(self, power, duration, efficiency)
    efficiency = efficiency or 0.98
    self._temp = self._temp + _get_deltaT(self, power * efficiency, duration)
    return self._temp
end

---Make the content loose heat.
---@param self room_obj
---@param duration number The duration in seconds.
---@param ambient_temp number The ambient temperature in degree celsius.
---@param heat_loss_factor number Increase or decrease the heat loss by a specified factor.
---@return number
M.cool = function(self, duration, ambient_temp, heat_loss_factor)
    -- Q = k_w * A * (T_room - T_ambient)
    -- P = Q / t
    local Q = self.THERMAL_CONDUCTIVITY_WALLS * self._surface * (self._temp - ambient_temp)
    local power = Q / duration

    -- W to kW
    power = power / 1000
    self._temp = self._temp - _get_deltaT(self, power, duration) * heat_loss_factor
    return self._temp
end

---initialize the simulator object
---@param self room_obj
---@param diameter number
---@param volume number
---@param temp number
---@param density number
local function init(self, diameter, volume, temp, density)
    self._mass = volume * density
    self._temp = temp

    local radius = diameter / 2

    -- height in cm
    local height = (volume * 1000) / (math.pi * (radius ^ 2))

    -- surface in m^2
    self._surface = (2 * math.pi * (radius ^ 2) + 2 * math.pi * radius * height) / 10000
end

--- instantiate new room (simulator)
---@param diameter number room diameter in centimeters
---@param volume number Content volume in liters
---@param temp number Initial content temperature in degree celsius
---@param density? number Content density
---@return room_obj
local function main(diameter, volume, temp, density)
    local o = setmetatable(newInst(), M)
    init(o, diameter, volume, temp, (density or 1))

    return o
end

return main
