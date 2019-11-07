game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local obstacle = {
    mk = function(x, y, w, h, sprite)
        local o = game_obj.mk('obs', 'obs', x, y)
        o.w = w
        o.h = h
        o.vel = v2.zero()

        renderer.attach(o, sprite)
        o.renderable.draw_order = 10

        o.get_rect = function(self)
            return { game_obj.pos(self), game_obj.pos(self) + v2.mk(self.w - 1, self.h - 1) }
        end

        o.get_centre = function(self)
            return v2.mk(self.x + self.w / 2, self.y + self.h / 2)
        end

        o.update = function(self)
            self.x += self.vel.x
            self.y += self.vel.y
        end

        return o
    end
}

return obstacle
