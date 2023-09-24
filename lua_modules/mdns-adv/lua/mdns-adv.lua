local modname = ...

local mdns = require("mdns")
local ds = require("device-settings")

local hostname = ds("wifi-sta").hostname

---@class mdns_srv_cfg
---@field portDS? string factory settings module, containing "port" field, if port is needed
---@field properties {[string]:string} mDNS properties, "service" being most important

---@class mdns_cfg
---@field services mdns_srv_cfg[]

---@param s mdns_srv_cfg
local function resolvePortIfAsked(s)
    if s.portDS then
        local port = ds(s.portDS).port
        s.properties.port = port
    end
end

---@param s mdns_srv_cfg
local function adventiseService(s)
    resolvePortIfAsked(s)
    mdns.register(hostname, s.properties)
end

---@param lst mdns_srv_cfg[]
local function adventiseAllServices(lst)
    for _, s in ipairs(lst) do
        adventiseService(s)
    end
end

---Start/stop mDNS advertisement
---@param operation string one of {start,stop}
local function main(operation)
    package.loaded[modname] = nil

    ---@type mdns_cfg
    local ms = ds(modname)

    if operation == "start" then
        adventiseAllServices(ms.services)
    else
        mdns.close()
    end
end

return main
