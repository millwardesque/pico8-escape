game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local FRAME_LEN = 10 -- Frames per anim frame

local actor = {
    mk = function(name, type, x, y, sprite, anims)
        local a = game_obj.mk(name, type, x, y)

        a.w = 8
        a.h = 8
        a.vel = v2.zero()
        a.last_pos = v2.zero()

        a.sprite = sprite
        a.anims = anims
        a.current_anim = nil
        a.anim_frame_index = 0
        a.anim_frame_count = 0

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
            self.anim_frame_count = (self.anim_frame_count + 1) % FRAME_LEN
            if self.anim_frame_count == 0 then
                self.anim_frame_index = (self.anim_frame_index + 1) % #self.current_anim
                self.renderable.sprite = self.current_anim[self.anim_frame_index + 1]
            end

            self.last_pos = game_obj.pos(self)
            self.x += self.vel.x
            self.y += self.vel.y
        end

        a.set_anim = function(self, name)
            self.current_anim = self.anims[name]
            self.anim_frame_index = 0
            self.anim_frame_count = 0
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
