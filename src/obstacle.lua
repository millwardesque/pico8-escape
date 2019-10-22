game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local obstacle = {
    mk = function(x, y, width, height, sprite)
        local o = game_obj.mk('obstacle', 'obstacle', x, y)
        o.width = width
        o.height = height
        o.vel = v2.zero()

        renderer.attach(o, sprite)
        o.renderable.draw_order = 10

        o.get_rect = function(self)
            return { self.v2_pos(self), self.v2_pos(self) + v2.mk(self.width - 1, self.height - 1) }
        end

        o.update = function(self)
            self.x += self.vel.x
            self.y += self.vel.y
        end

        return o
    end
}

return obstacle
