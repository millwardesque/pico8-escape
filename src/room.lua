game_obj = require('game_obj')
renderer = require('renderer')
utils = require('utils')

local room = {
    mk = function(x, y, x_dim, y_dim, tileset, doors)
        local r = game_obj.mk('room', 'room', x, y)
        r.x_dim = x_dim
        r.y_dim = y_dim
        r.tileset = tileset
        r.doors = doors

        renderer.attach(r, tileset)

        r.renderable.render = function(renderable, x, y)
            go = renderable.game_obj

            renderable.sprite = go.tileset
            for col=0, go.x_dim - 1 do
                for row=0, go.y_dim - 1 do
                    x_offset = col * 8
                    y_offset = row * 8

                    renderable.default_render(renderable, x + x_offset, y + y_offset)
                end
            end

            renderable.sprite = go.tileset + 1
            for door in all(go.doors) do
                x_offset = door.x * 8
                y_offset = door.y * 8
                renderable.default_render(renderable, x + x_offset, y + y_offset)
            end

            -- Draw door collider corners
            for door in all(go.doors) do
                door_rect = go.get_door_rect(go, door)
                pset(door_rect[1].x, door_rect[1].y)
                pset(door_rect[2].x, door_rect[1].y)
                pset(door_rect[2].x, door_rect[2].y)
                pset(door_rect[1].x, door_rect[2].y)
            end
        end

        r.get_door_rect = function(self, door)
            local door_origin = self.v2_pos(self) + v2.mk(door.x * 8, door.y * 8)
            return { door_origin, door_origin + v2.mk(8 - 1, 8 - 1) }
        end

        r.check_doors = function(self, p1)
            p1_rect = p1.get_rect(p1)

            for door in all(self.doors) do
                door_rect = self.get_door_rect(self, door)

                if utils.square_col(door_rect[1], door_rect[2], p1_rect[1], p1_rect[2]) then
                    return door
                end
            end

            return nil
        end

        return r
    end
}

return room
