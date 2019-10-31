game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local player = {
    mk = function(x, y, sprite)
        local p = game_obj.mk('player', 'player', x, y)

        p.w = 8
        p.h = 8
        p.sprite = sprite
        p.vel = v2.zero()
        p.last_pos = v2.zero()
        p.max_stamina = 100
        p.stamina = 100


        renderer.attach(p, sprite)
        p.renderable.draw_order = 10

        p.get_rect = function(self)
            return { self.v2_pos(self), self.v2_pos(self) + v2.mk(self.w - 1, self.h - 1) }
        end

        p.get_last_rect = function(self)
            return { self.last_pos, self.last_pos + v2.mk(self.w - 1, self.h - 1) }
        end

        p.get_centre = function(self)
            return v2.mk(self.x + self.w / 2, self.y + self.h / 2)
        end

        p.update = function(self)
            self.last_pos = self.v2_pos(self)

            self.x += self.vel.x
            self.y += self.vel.y
        end

        p.injure = function(self, damage)
            self.max_stamina = max(0, self.max_stamina - damage)
            self.set_stamina(self, self.stamina)
        end

        p.set_stamina = function(self, new_stamina)
            self.stamina = min(self.max_stamina, max(0, new_stamina))
        end

        p.renderable.render = function(renderable, x, y)
            local go = renderable.game_obj
            renderable.default_render(renderable, x, y)

            -- Draw previous frame's rect
            local rect = go.get_last_rect(go)
            utils.draw_corners(rect)
        end

        return p
    end
}

return player
