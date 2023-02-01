local kettleFact = require("kettle")
local pidFact = require("pid")
local dequeFact = require("mini-deque")
local round = require("round")
local timeObj = require("time-obj")

---@class simulationPid_args_set
---@field name string
---@field kp number
---@field ki number
---@field kd number

---@class simulationPid_args
---@field delay number
---@field sampletime number
---@field pid simulationPid_args_set[]
---@field out_min number
---@field out_max number
---@field diameter number
---@field volume number
---@field kettle_temp number
---@field interval integer
---@field setpoint number
---@field verbose boolean
---@field heater_power number
---@field ambient_temp number
---@field heat_loss_factor number

---@class simulationPid_obj
---@field name  string
---@field sut  pidSim_obj
---@field kettle  kettle_obj
---@field delayed_temps  deque_obj
---@field timestamps number[]
---@field heater_temps number[]
---@field sensor_temps number[]
---@field outputs number[]
local M = {}
M.__index = M

---instantiate new simulation object
---@param name string
---@param sut pidSim_obj
---@param kettle kettle_obj
---@param delayed_temps deque_obj
---@param timestamps number[]
---@param heater_temps number[]
---@param sensor_temps number[]
---@param outputs number[]
---@return simulationPid_obj
local function simulationFact(name, sut, kettle, delayed_temps, timestamps, heater_temps, sensor_temps, outputs)
    local o = setmetatable({
        name = name,
        sut = sut,
        kettle = kettle,
        delayed_temps = delayed_temps,
        timestamps = timestamps,
        heater_temps = heater_temps,
        sensor_temps = sensor_temps,
        outputs = outputs,
    }, M)
    return o
end

local function prnt(...)
    print(string.format(...))
end

---populate simulator object with simulation data
---@param sim simulationPid_obj
---@param timestamp integer
---@param output number
---@param args simulationPid_args
local function sim_update(sim, timestamp, output, args)
    sim.kettle:heat(args.heater_power * (output / 100), args.sampletime)
    sim.kettle:cool(args.sampletime, args.ambient_temp, args.heat_loss_factor)
    sim.delayed_temps:append(sim.kettle:temperature())
    table.insert(sim.timestamps, timestamp)
    table.insert(sim.outputs, output)
    table.insert(sim.sensor_temps, sim.delayed_temps:peekFirst())
    table.insert(sim.heater_temps, sim.kettle:temperature())
end

---@param args simulationPid_args
---@return simulationPid_obj[]
local function initSimulation(args)
    local delayed_temps_len = math.max(1, round(args.delay / args.sampletime))

    --@type simulationPid_obj[]
    local sims = {}

    for _, pid in ipairs(args.pid) do
        local sim = simulationFact(
            pid.name,
            pidFact(
                args.sampletime, pid.kp, pid.ki, pid.kd,
                args.out_min, args.out_max, timeObj.fnc),
            kettleFact(args.diameter, args.volume, args.kettle_temp),
            dequeFact(delayed_temps_len, args.kettle_temp),
            {}, {}, {}, {}
        )
        table.insert(sims, sim)
    end

    return sims
end

---Run simulation for specified interval
---@param sims simulationPid_obj[]
---@param args simulationPid_args
local function runSimulation(sims, args)
    timeObj.timestamp = 0 -- seconds
    while timeObj.timestamp < (args.interval * 60) do
        timeObj.timestamp = timeObj.timestamp + args.sampletime

        for _, sim in ipairs(sims) do
            local output = sim.sut:calc(sim.delayed_temps:peekFirst(), args.setpoint)
            output = math.max(output, 0)
            output = math.min(output, 100)
            sim_update(sim, timeObj.timestamp, output, args)

            if args.verbose then
                prnt('time:    %.1f sec', timeObj.timestamp)
                prnt('%s: %.2f%%', sim.name, output)
                prnt('temp sensor:    %.2f°C', sim.sensor_temps[#sim.sensor_temps])
                prnt('temp heater:    %.2f°C', sim.heater_temps[#sim.heater_temps])
                prnt("")
            end
        end
    end
end

---run simulation with given settings
---@param args simulationPid_args
---@return simulationPid_obj[]
local function main(args)
    local sims = initSimulation(args)
    runSimulation(sims, args)
    return sims
end

return main
