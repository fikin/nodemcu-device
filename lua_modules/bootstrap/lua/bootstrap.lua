local modname = ...

local file, log = require("file"), require("log")

local fName = "bootstrap-sw"
local fNameErr = "bootstrap-sw.PANIC.txt"

local function main()
    package.loaded[modname] = nil

    for _, ext in ipairs({ ".lc", ".lua" }) do
        local f = fName .. ext
        if file.exists(f) then
            log.info("running %s", f)

            file.remove(fNameErr) -- remove old error

            local ok, err = pcall(require, fName)

            file.remove(f) -- make sure next reboot we do not repeat it

            if not ok then
                log.error("bootstrap failed : %s : %s", f, err)
                file.remove(fNameErr)
                file.putcontents(fNameErr, err)
                error(err)
            end

            collectgarbage("collect")
            collectgarbage("collect")
            return
        end
    end
    log.info("no bootstrap-sw found")
end

return main
