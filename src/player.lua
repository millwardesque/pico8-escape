actor = require('actor')

local player = {
    mk = function(x, y, sprite)
        local p = actor.mk('player', 'player', x, y, sprite)

        p.max_stamina = 100
        p.stamina = 100
        p.renderable.draw_order = 10

        p.injure = function(self, damage)
            self.max_stamina = max(0, self.max_stamina - damage)
            self.set_stamina(self, self.stamina)
        end

        p.set_stamina = function(self, stamina)
            self.stamina = min(self.max_stamina, max(0, stamina))
        end

        return p
    end
}

return player
