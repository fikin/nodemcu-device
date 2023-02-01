require("nodemcu").reset()

local file = require("file")
local sjson = require("sjson")
local sim = require("simulate-autotune")

---@param fName any
---@return table
local function jf(fName)
    return assert(sjson.decode(assert(file.getcontents(fName))))
end

---@param txt string[] output text
---@param sim autotunePid_obj
local function toCsv(txt, sim)
    for i = 1, #sim.timestamps do
        local str = string.format("%.1f;%.2f;%.2f;%.2f",
            sim.timestamps[i], sim.outputs[i], sim.sensor_temps[i], sim.heater_temps[i])
        table.insert(txt, str)
    end
end

---@param sim autotunePid_obj
local function writeCsv(sim)
    local fname = "out/" .. sim.name .. ".csv"
    local txt = { "timestamp;output;sensor_temp;heater_temp" }
    toCsv(txt, sim)
    assert(file.putcontents(fname, table.concat(txt, '\n')))
end

---@param fname string
---@param args autotunePid_args
---@param sim autotunePid_obj
local function writeJson(fname, args, sim)
    local title = string.format('Autotune simulation, %.1fl %s, %.1fkW heater, %.1fs delay',
        args.volume, args.device_type, args.heater_power, args.delay)
    local o = { {
        heater_temps = sim.heater_temps,
        name = sim.name,
        outputs = sim.outputs,
        sensor_temps = sim.sensor_temps,
        timestamps = sim.timestamps,
    } }
    local enc = sjson.encoder({
        title = title,
        args = args,
        coefficients = sim.sut:tuningResults(),
        sims = o,
    })
    assert(file.putcontents(fname, assert(enc:read(1024 * 1024 * 10))))
end

local function main()
    ---@type autotunePid_args
    local args = jf("autotune-simulation-args.json")
    local sim = sim(args)
    writeCsv(sim)
    writeJson("out/autotune-simulation-results.json", args, sim)
end

main()
