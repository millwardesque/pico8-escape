local level = {
    mk = function()
        return {
            p1 = nil,
            v1 = nil,
            level_timer = 0,
            room_timer = 0,
            rooms = {},
            flags = {},
            -- Eventually: corpses, flags, items, etc.
        }
    end,
}
return level
