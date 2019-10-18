game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local villain = {
    mk = function(x, y, sprite, target, speed)
        local v = game_obj.mk('villain', 'villain', x, y)
        v.sprite = sprite
        v.target = target
        v.speed = speed
        v.state = "pursuit"
        v.stun_length = 0
        v.stun_elapsed = 0

        v.vel = v2.zero()
        v.dir_to_target = v2.zero()

        renderer.attach(v, sprite)
        v.renderable.draw_order = 10

        v.dislodge = function(self, p1, push_amount, stun_length)
            -- Push away from target back
            local push_vec = self.dir_to_target(self) * -1 * push_amount
            self.x += push_vec.x
            self.y += push_vec.y

            self.state = "stunned"
            self.stun_length = stun_length
        end

        v.dir_to_target = function(self)
            local d = self.target.v2_pos(self.target) - self.v2_pos(self)
            local dist = v2.mag(d)
            return v2.norm(d)
        end

        v.is_stunned = function(self)
            return self.state == "stunned"
        end

        v.update = function(self)
            if self.state == "pursuit" then
                self.vel =  self.dir_to_target(self) * self.speed
            elseif self.is_stunned(self) then
                self.stun_elapsed += 1
                self.vel = v2.zero()

                if self.stun_elapsed == self.stun_length then
                    self.stun_elapsed = 0
                    self.stun_length = 0
                    self.state = "pursuit"
                end
            end

            self.x += self.vel.x
            self.y += self.vel.y
        end

        v.get_rect = function(self)
            return { self.v2_pos(self), self.v2_pos(self) + v2.mk(8 - 1, 8 - 1) }
        end

        return v
    end
}

return villain
