---@class kettle_obj
--- specific heat capacity of water: c = 4.182 kJ / kg * K
---@field SPECIFIC_HEAT_CAP_WATER number
--- thermal conductivity of steel: lambda = 15 W / m * K
---@field THERMAL_CONDUCTIVITY_STEEL number
--- kettle's temperature
---@field _temp number
--- kettle's surface area
---@field _surface number
---kettle's water mass
---@field _mass number
local M = {}
M.__index = M

---@return kettle_obj
local function newInst()
    return {
        --- specific heat capacity of water: c = 4.182 kJ / kg * K
        ---@type number
        SPECIFIC_HEAT_CAP_WATER = 4.182,

        --- thermal conductivity of steel: lambda = 15 W / m * K
        ---@type number
        THERMAL_CONDUCTIVITY_STEEL = 15,

        --- kettle's temperature
        ---@type number
        _temp = 0,
        --- kettle's surface area
        ---@type number
        _surface = 0,
        ---kettle's water mass
        ---@type number
        _mass = 0,
    }
end

---calculate temperature change for given duration and applied power
---@param self kettle_obj
---@param power number
---@param duration number
---@return number
local function _get_deltaT(self, power, duration)
    -- P = Q / t
    -- Q = c * m * delta T
    -- => delta(T) = (P * t) / (c * m)
    return ((power * duration) / (self.SPECIFIC_HEAT_CAP_WATER * self._mass))
end

---get current kettle temperature
---@param self kettle_obj
---@return number
M.temperature = function(self)
    return self._temp
end

---Heat the kettle's content.
---@param self kettle_obj
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
---@param self kettle_obj
---@param duration number The duration in seconds.
---@param ambient_temp number The ambient temperature in degree celsius.
---@param heat_loss_factor number Increase or decrease the heat loss by a specified factor.
---@return number
M.cool = function(self, duration, ambient_temp, heat_loss_factor)
    -- Q = k_w * A * (T_kettle - T_ambient)
    -- P = Q / t
    local power = ((self.THERMAL_CONDUCTIVITY_STEEL * self._surface
        * (self._temp - ambient_temp)) / duration)

    -- W to kW
    power = power / 1000
    self._temp = self._temp - _get_deltaT(self, power, duration) * heat_loss_factor
    return self._temp
end

---initialize the simulator object
---@param self kettle_obj
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

--- instantiate new kettle (simulator)
---@param diameter number Kettle diameter in centimeters
---@param volume number Content volume in liters
---@param temp number Initial content temperature in degree celsius
---@param density? number Content density
---@return kettle_obj
local function main(diameter, volume, temp, density)
    local o = setmetatable(newInst(), M)
    init(o, diameter, volume, temp, (density or 1))

    return o
end

return main
