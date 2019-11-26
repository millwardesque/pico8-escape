actor = require('actor')
game_obj  = require('game_obj')

local villain = {
    mk = function(x, y, sprite, target, speed)
        local anims = {}
        anims['walk'] = {sprite, sprite + 1, sprite + 2, sprite + 3}

        local v = actor.mk('villain', 'villain', x, y, sprite, anims)

        v.target = target
        v.path = nil
        v.speed = speed
        v.state = "hiding"
        v.stun_length = 0
        v.stun_elapsed = 0
        v.path_index = nil
        v.hiding_distance = 30
        v.set_anim(v, 'walk')

        v.renderable.draw_order = 10

        v.renderable.render = function(self, x, y)
            local go = self.game_obj

            if go.state != "hiding" then
                self.default_render(self, x, y)
            end

            if go.state == "pursuit" and go.path != nil then
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
        end

        v.set_path = function(self, new_path)
            self.path = new_path
            self.path_index = 1
        end

        v.dislodge = function(self, p1, push_amount, stun_length)
            -- Push away from target back
            local push_vec = self.dir_to_point(self, game_obj.pos(self.target)) * -1 * push_amount
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
                if self.path != nil then
                    if self.path_index > #(self.path) then
                        self.vel = self.dir_to_point(self, game_obj.pos(self.target)) * self.speed
                    else
                        local rect = self.get_rect(self)
                        if utils.pt_in_rect(self.path[self.path_index], rect[1], rect[2]) then
                            self.path_index += 1
                        end

                        if self.path_index > #(self.path) then
                            self.vel = self.dir_to_point(self, game_obj.pos(self.target)) * self.speed
                        else
                            self.vel = self.dir_to_point(self, self.path[self.path_index]) * self.speed
                        end
                    end

                    if self.vel.x > 0 then
                        self.renderable.flip_x = false
                    elseif self.vel.x < 0 then
                        self.renderable.flip_x = true
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
            elseif self.state == "hiding" then
                self.vel = v2.zero()
                if self.dist_to_point(self, self.target.get_centre(self.target)) < self.hiding_distance then
                    self.state = "pursuit"
                end
            end

            self.default_update(self)
        end

        return v
    end
}

return villain
