local file, log = require("file"), require("log")

local fName = "bootstrap-sw.lua"
local fNameErr = "bootstrap-sw.PANIC.txt"

local function main()
    if file.exists(fName) then
        log.info("running %s", fName)

        local ok, err = pcall(require, "bootstrap-sw")

        file.remove(fName)

        if not ok then
            log.error("bootstrap failed : %s : %s", fName, err)
            file.remove(fNameErr)
            file.putcontents(fNameErr, err)
        end

        collectgarbage()
        collectgarbage()
    end
end

return main
