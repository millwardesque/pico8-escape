game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local player = {
    mk = function(x, y, sprite)
        local p = game_obj.mk('player', 'player', x, y)
        p.sprite = sprite
        p.vel = v2.zero()

        renderer.attach(p, sprite)
        p.renderable.draw_order = 10

        p.get_rect = function(self)
            return { self.v2_pos(self), self.v2_pos(self) + v2.mk(8 - 1, 8 - 1) }
        end

        p.update = function(self)
            self.x += self.vel.x
            self.y += self.vel.y
        end

        p.renderable.render = function(renderable, x, y)
            local go = renderable.game_obj
            renderable.default_render(renderable, x, y)

            -- Draw collider corners
            local rect = go.get_rect(go)
            pset(rect[1].x, rect[1].y)
            pset(rect[2].x, rect[1].y)
            pset(rect[2].x, rect[2].y)
            pset(rect[1].x, rect[2].y)
        end

        return p
    end
}

return player
