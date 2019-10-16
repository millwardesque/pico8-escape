game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local villain = {
    mk = function(x, y, sprite, target, speed)
        local v = game_obj.mk('villain', 'villain', x, y)
        v.sprite = sprite
        v.target = target
        v.speed = speed

        v.vel = v2.zero()
        v.dir_to_target = v2.zero()

        renderer.attach(v, sprite)
        v.renderable.draw_order = 10

        v.update = function(self)
            local d = self.target.v2_pos(self.target) - self.v2_pos(self)
            local dist = v2.mag(d)
            local dir_to_target = v2.norm(d)
            self.vel =  dir_to_target * self.speed

            self.x += self.vel.x
            self.y += self.vel.y
        end

        return v
    end
}

return villain
