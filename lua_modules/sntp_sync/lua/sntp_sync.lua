--[[
  Performs SNTP sync.
  
  Depends on : log, sntp
  
  Usage: 
    require("sntp-sync")()
]] --

local modname = ...

local function main()
  package.loaded[modname] = nil

  local wifievent, wifi = require("wifi_event"), require("wifi")

  -- auto-keep time up to date when connected to network
  wifievent(
    "sntp_sync",
    wifi.eventmon.STA_GOT_IP,
    function()
      require("sntp").sync(
        nil, -- TODO use device_settings to get configurable list of servers
        function(sec, micro, srv, info)
          local log = require("log")
          log.info(log.json({sec = sec, micro = micro, srv = srv, info = info}))
        end,
        function(code, err)
          local wifi = require("wifi")
          local mode = wifi.getmode()
          if mode == wifi.STATION or mode == wifi.STATIONAP then
            if wifi.sta.status() == wifi.STA_GOTIP then
              -- report error only if wifi is connected
              local codes = {
                ["1"] = "DNS lookup failed",
                ["2"] = "Memory allocation failure",
                ["3"] = "UDP send failed",
                ["4"] = "Timeout, no NTP response received"
              }
              require("log").error(codes[tostring(code)], err)
            end
          end
        end,
        1
      )
    end
  )
end

return main
