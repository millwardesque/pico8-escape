game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local villain = {
    mk = function(x, y, sprite, target, speed)
        local v = game_obj.mk('villain', 'villain', x, y)

        v.w = 8
        v.h = 8
        v.sprite = sprite
        v.target = target
        v.path = nil
        v.speed = speed
        v.state = "pursuit"
        v.stun_length = 0
        v.stun_elapsed = 0
        v.path_index = nil

        v.last_pos = v2.zero()
        v.vel = v2.zero()
        v.dir_to_target = v2.zero()

        renderer.attach(v, sprite)
        v.renderable.draw_order = 10

        v.renderable.render = function(self, x, y)
            self.default_render(self, x, y)

            local path = self.game_obj.path
            for i=1,#path do
                if i < self.game_obj.path_index then
                    color(5)
                else
                    color(7)
                end
                circfill(path[i].x, path[i].y, 0.5)
            end
        end

        v.set_path = function(self, new_path)
            self.path = new_path
            self.path_index = 1
        end

        v.dislodge = function(self, p1, push_amount, stun_length)
            -- Push away from target back
            local push_vec = self.dir_to_point(self, self.target.v2_pos(self.target)) * -1 * push_amount
            self.x += push_vec.x
            self.y += push_vec.y

            self.state = "stunned"
            self.stun_length = stun_length
        end

        v.dir_to_point = function(self, point)
            local d = point - self.get_centre(self)
            return v2.norm(d)
        end

        v.dist_to_point = function(self, point)
            local d = point - self.get_centre(self)
            return v2.mag(d)
        end

        v.is_stunned = function(self)
            return self.state == "stunned"
        end

        v.update = function(self)
            if self.state == "pursuit" then
                log.log("V: "..self.path_index.."/"..#(self.path).." ("..v2.str(self.path[self.path_index])..")")
                if self.path != nil then
                    if self.path_index > #(self.path) then
                        self.vel = self.dir_to_point(self, self.target.v2_pos(self.target)) * self.speed
                    else
                        local rect = self.get_rect(self)
                        if utils.pt_in_rect(self.path[self.path_index], rect[1], rect[2]) then
                            self.path_index += 1
                        end

                        if self.path_index > #(self.path) then
                            self.vel = self.dir_to_point(self, self.target.v2_pos(self.target)) * self.speed
                        else
                            self.vel = self.dir_to_point(self, self.path[self.path_index]) * self.speed
                        end
                    end
                end
            elseif self.is_stunned(self) then
                self.stun_elapsed += 1
                self.vel = v2.zero()

                if self.stun_elapsed == self.stun_length then
                    self.stun_elapsed = 0
                    self.stun_length = 0
                    self.state = "pursuit"
                end
            end

            self.last_pos = self.v2_pos(self)
            self.x += self.vel.x
            self.y += self.vel.y
        end

        v.get_rect = function(self)
            return { self.v2_pos(self), self.v2_pos(self) + v2.mk(self.w - 1, self.h - 1) }
        end

        v.get_last_rect = function(self)
            return { self.last_pos, self.last_pos + v2.mk(self.w - 1, self.h - 1) }
        end

        v.get_centre = function(self)
            return v2.mk(self.x + self.w / 2, self.y + self.h / 2)
        end

        return v
    end
}

return villain
