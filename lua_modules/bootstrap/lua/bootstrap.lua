local modname = ...

local file, log = require("file"), require("log")

local fName = "bootstrap-sw"
local fNameErr = "bootstrap-sw.PANIC.txt"

local function main()
    package.loaded[modname] = nil

    for _, ext in ipairs({".lc", ".lua"}) do
        local f = fName .. ext
        if file.exists(f) then
            log.info("running %s", f)
    
            local ok, err = pcall(require, "bootstrap-sw")
    
            file.remove(f)
    
            if not ok then
                log.error("bootstrap failed : %s : %s", f, err)
                file.remove(fNameErr)
                file.putcontents(fNameErr, err)
            end
    
            collectgarbage()
            collectgarbage()

            return
        end
    end
end

return main
