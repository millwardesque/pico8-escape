actor = require('actor')

local player = {
    mk = function(x, y, sprite)
        local anims = {}
        anims['walk'] = {sprite, sprite + 1, sprite + 2, sprite + 3}

        local p = actor.mk('player', 'player', x, y, sprite, anims)

        p.max_stamina = 100
        p.stamina = 100
        p.renderable.draw_order = 10
        p.set_anim(p, 'walk')

        p.injure = function(self, damage)
            self.max_stamina = max(0, self.max_stamina - damage)
            self.set_stamina(self, self.stamina)
        end

        p.set_stamina = function(self, stamina)
            self.stamina = min(self.max_stamina, max(0, stamina))
        end

        p.update = function(self)
            self.default_update(self)

            if self.vel.x > 0 then
                self.renderable.flip_x = false
            elseif self.vel.x < 0 then
                self.renderable.flip_x = true
            end
        end

        return p
    end
}

return player
