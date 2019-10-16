v2 = require('v2')

local game_obj = {
    mk = function(name, type, pos_x, pos_y)
        local g = {
            name = name,
            type = type,
            x = pos_x,
            y = pos_y,
        }
        g.update = function(self)
        end

        g.v2_pos = function(self)
            return v2.mk(self.x, self.y)
        end

        return g
    end
}
return game_obj
