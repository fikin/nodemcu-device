---@class autotunePid_args
---@field delay number
---@field sampletime number
---@field out_min number
---@field out_max number
---@field diameter number
---@field volume number
---@field device_type string -- one of [kettle, room]
---@field device_temp number
---@field setpoint number
---@field verbose boolean
---@field heater_power number
---@field ambient_temp number
---@field heat_loss_factor number
---@field lookback number
---@field noiseband number

---@class autotunePid_obj
---@field name  string
---@field sut  autotune_obj
---@field device  device_sim
---@field delayed_temps  deque_obj
---@field timestamps number[]
---@field heater_temps number[]
---@field sensor_temps number[]
---@field outputs number[]
local M = {}
M.__index = M

local autotuneFact = require("autotune")
local dequeFact = require("mini-deque")
local round = require("round")
local timeObj = require("time-obj")

local function prnt(...)
    print(string.format(...))
end

---instantiate new simulation object
---@param name string
---@param sut autotune_obj
---@param device device_sim
---@param delayed_temps deque_obj
---@param timestamps number[]
---@param heater_temps number[]
---@param sensor_temps number[]
---@param outputs number[]
---@return autotunePid_obj
local function simulationFact(name, sut, device, delayed_temps, timestamps, heater_temps, sensor_temps, outputs)
    local o = setmetatable({
        name = name,
        sut = sut,
        device = device,
        delayed_temps = delayed_temps,
        timestamps = timestamps,
        heater_temps = heater_temps,
        sensor_temps = sensor_temps,
        outputs = outputs,
    }, M)
    return o
end

---@param args autotunePid_args
---@return autotunePid_obj
local function initSimulation(args)
    local delayed_temps_len = math.max(1, round(args.delay / args.sampletime))

    return simulationFact(
        "autotune",
        autotuneFact(args.setpoint, 100, args.sampletime, args.lookback, args.out_min, args.out_max, args.noiseband,
            timeObj.fnc),
        require(args.device_type)(args.diameter, args.volume, args.device_temp),
        dequeFact(delayed_temps_len, args.device_temp),
        {}, {}, {}, {}
    )
end

---populate simulator object with simulation data
---@param sim autotunePid_obj
---@param timestamp integer
---@param output number
---@param args autotunePid_args
local function sim_update(sim, timestamp, output, args)
    sim.device:heat(args.heater_power * (output / 100), args.sampletime)
    sim.device:cool(args.sampletime, args.ambient_temp, args.heat_loss_factor)
    sim.delayed_temps:append(sim.device:temperature())
    table.insert(sim.timestamps, timestamp)
    table.insert(sim.outputs, output)
    table.insert(sim.sensor_temps, sim.delayed_temps:peekFirst())
    table.insert(sim.heater_temps, sim.device:temperature())
end

---Run simulation for specified interval
---@param sim autotunePid_obj
---@param args autotunePid_args
local function runSimulation(sim, args)
    timeObj.timestamp = 0 -- seconds
    while not sim.sut:run(sim.delayed_temps:peekFirst()) do
        timeObj.timestamp = timeObj.timestamp + args.sampletime

        sim_update(sim, timeObj.timestamp, sim.sut:output(), args)

        if args.verbose then
            prnt('time:    %.1f sec', timeObj.timestamp)
            prnt('state: %s', sim.sut:state())
            prnt('%s: %.2f', sim.name, sim.sut:output())
            prnt('temp sensor:    %.2f°C', sim.sensor_temps[#sim.sensor_temps])
            prnt('temp heater:    %.2f°C', sim.heater_temps[#sim.heater_temps])
            prnt("")
        end
    end

    prnt('time:    %d min', round(timeObj.timestamp / 60))
    prnt('state:   %s', sim.sut:state())
    prnt("")

    -- On success, print params for each tuning rule
    if sim.sut:state() == sim.sut.STATE_SUCCEEDED then
        for rule, params in pairs(sim.sut:tuningResults()) do
            prnt('rule: %s', rule)
            prnt('Kp: %f', params.kp)
            prnt('Ki: %f', params.ki)
            prnt('Kd: %f', params.kd)
            prnt("")
        end
    end
end

---run simulation with given settings
---@param args autotunePid_args
---@return autotunePid_obj
local function main(args)
    local sims = initSimulation(args)
    runSimulation(sims, args)
    return sims
end

return main
