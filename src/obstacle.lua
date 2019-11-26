actor = require('actor')
game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local obstacle = {
    mk = function(x, y, w, h, sprite)
        local o = actor.mk('obs', 'obs', x, y, sprite, nil)

        return o
    end
}

return obstacle
