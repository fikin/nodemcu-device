--[[
    rsyslog UDP sender.

    It expects to be connected to wifi STATION and prefers to have hostname defined.
]]

local modname = ...

---@class rsyslog_cfg
---@field host string rsyslog server
---@field port integer rsyslog server port

---@class rsyslog_state
---@field ip string dns resolved rsyslog server ip

---@type rsyslog_cfg
local cfg = require("device-settings")(modname)

---@type rsyslog_state
local state = require("state")(modname)

local function decodeLvl(lvl)
    if lvl == "DEBUG" then
        return "15"
    elseif lvl == "INFO" then
        return "14"
    elseif lvl == "ERROR" then
        return "11"
    else -- "AUDIT"
        return "110"
    end
end

---creates rsyslog udp package
---@param lvl string log level in all-caps
---@param ts string timestamp
---@param src string source:line
---@param msg string message
---@return string
local function createPacket(lvl, ts, src, msg)
    local arr = {}
    table.insert(arr, "<")
    table.insert(arr, decodeLvl(lvl))
    table.insert(arr, ">1 ")
    table.insert(arr, ts)
    table.insert(arr, " ")
    table.insert(arr, require("wifi").sta.gethostname() or "-")
    table.insert(arr, " ")
    table.insert(arr, src)
    table.insert(arr, " - - - - ")
    table.insert(arr, msg)
    return table.concat(arr)
end

---callback from dns() function lookup for rsyslog server host
---@param _ socket
---@param ip2 string
local function onDnsHostLookup(_, ip2)
    state.ip = ip2
    require("log").info("dns lookup : %s : %s", cfg.host, ip2)
end

---checks if device has IP adderess assigned
---@return boolean
local function isConnected()
    local wifi = require("wifi")
    return wifi.sta.status() == wifi.STA_GOTIP
end

---returns a function one can use to send log messages via rsyslog protocol
---@return logfunc
local function main()
    package.loaded[modname] = nil

    local u = require("net").createUDPSocket()

    if isConnected() then
        u:dns(cfg.host, onDnsHostLookup)
    end

    ---@type logfunc
    return function(syslogLevel, ts, src, msg)
        local txt = createPacket(syslogLevel, ts, src, msg)
        if isConnected() then
            if state.ip then
                u:send(cfg.port, state.ip, txt)
            else
                u:dns(cfg.host, onDnsHostLookup)
            end
        else
            ip = nil
        end
        print(txt)
    end
end

return main
