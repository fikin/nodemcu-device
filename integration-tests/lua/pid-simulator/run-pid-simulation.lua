require("nodemcu").reset()

local file = require("file")
local sjson = require("sjson")
local sim = require("simulate-pid")


---@param fName any
---@return table
local function jf(fName)
    return assert(sjson.decode(assert(file.getcontents(fName))))
end

---@param txt string[] output text
---@param sim simulationPid_obj
local function toCsv(txt, sim)
    for i = 1, #sim.timestamps do
        local str = string.format("%.1f;%.2f;%.2f;%.2f",
            sim.timestamps[i], sim.outputs[i], sim.sensor_temps[i], sim.heater_temps[i])
        table.insert(txt, str)
    end
end

---@param sim simulationPid_obj
local function writeCsv(sim)
    local fname = "out/" .. sim.name .. ".csv"
    local txt = { "timestamp;output;sensor_temp;heater_temp" }
    toCsv(txt, sim)
    assert(file.putcontents(fname, table.concat(txt, '\n')))
end

---@param sims simulationPid_obj[]
local function writeCsvs(sims)
    for _, s in ipairs(sims) do
        writeCsv(s)
    end
end

---@param fname string
---@param args simulationPid_args
---@param sims simulationPid_obj[]
local function writeJson(fname, args, sims)
    local title = string.format('PID simulation, %.1fl kettle, %.1fkW heater, %.1fs delay',
        args.volume, args.heater_power, args.delay)
    local arr = {}
    for _, s in ipairs(sims) do
        local o = {
            heater_temps = s.heater_temps,
            name = s.name,
            outputs = s.outputs,
            sensor_temps = s.sensor_temps,
            timestamps = s.timestamps,
        }
        table.insert(arr, o)
    end
    local enc = sjson.encoder({ title = title, args = args, sims = arr })
    assert(file.putcontents(fname, assert(enc:read(1024 * 1024 * 10))))
end

local function main()
    ---@type simulationPid_args
    local args = jf("pid-simulation-args.json")
    local sims = sim(args)
    writeCsvs(sims)
    writeJson("out/pid-simulation-results.json", args, sims)
end

main()
