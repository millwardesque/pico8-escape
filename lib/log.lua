local log = {
    debug = true,
    file = 'debug.log',
    _data = {},

    log = function(msg)
        add(log._data, msg)
    end,
    syslog = function(msg)
        printh(msg, log.file)
    end,
    render = function()
        if log.debug then
            color(7)
            for i = 1, #log._data do
                print(log._data[i], 5, 5 + (8 * (i - 1)))
            end
        end

        log._data = {}
    end,
    tostring = function(any)
        if type(any)=="function" then
            return "function"
        end
        if any==nil then
            return "nil"
        end
        if type(any)=="string" then
            return any
        end
        if type(any)=="boolean" then
            if any then return "true" end
            return "false"
        end
        if type(any)=="table" then
            local str = "{ "
            for k,v in pairs(any) do
                str=str..log.tostring(k).."->"..log.tostring(v).." "
            end
            return str.."}"
        end
        if type(any)=="number" then
            return ""..any
        end
        return "unkown" -- should never show
    end
}
return log
