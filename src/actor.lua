game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local actor = {
    mk = function(name, type, x, y, sprite)
        local a = game_obj.mk(name, type, x, y)

        a.w = 8
        a.h = 8
        a.sprite = sprite
        a.vel = v2.zero()
        a.last_pos = v2.zero()

        renderer.attach(a, sprite)

        a.get_rect = function(self)
            return { game_obj.pos(self), game_obj.pos(self) + v2.mk(self.w - 1, self.h - 1) }
        end

        a.get_last_rect = function(self)
            return { self.last_pos, self.last_pos + v2.mk(self.w - 1, self.h - 1) }
        end

        a.get_centre = function(self)
            return v2.mk(self.x + self.w / 2, self.y + self.h / 2)
        end

        a.update = function(self)
            a.default_update(self)
        end

        a.default_update = function(self)
            self.last_pos = game_obj.pos(self)
            self.x += self.vel.x
            self.y += self.vel.y
        end

        a.renderable.render = function(renderable, x, y)
            local go = renderable.game_obj
            renderable.default_render(renderable, x, y)

            -- Draw previous frame's rect
            -- local rect = go.get_last_rect(go)
            -- utils.draw_corners(rect)
        end

        return a
    end
}

return actor
