game_obj = require('game_obj')
renderer = require('renderer')
utils = require('utils')

local room = {
    mk = function(x, y, cols, rows, tileset)
        local r = game_obj.mk('room', 'room', x, y)
        r.cols = cols
        r.rows = rows
        r.tileset = tileset
        r.doors = {}

        renderer.attach(r, tileset)

        r.renderable.render = function(renderable, x, y)
            go = renderable.game_obj

            -- Draw floors
            renderable.sprite = go.tileset
            for col=0, go.cols - 1 do
                for row=0, go.rows - 1 do
                    x_offset = col * 8
                    y_offset = row * 8

                    renderable.default_render(renderable, x + x_offset, y + y_offset)
                end
            end

            -- Draw doors
            renderable.sprite = go.tileset + 1
            for door in all(go.doors) do
                x_offset = door.x * 8
                y_offset = door.y * 8
                renderable.default_render(renderable, x + x_offset, y + y_offset)
            end

            -- Draw door collider corners
            for door in all(go.doors) do
                door_rect = go.get_door_rect(go, door)
                utils.draw_corners(door_rect)
            end
        end

        r.get_door_rect = function(self, door)
            local door_origin = self.v2_pos(self) + v2.mk(door.x * 8, door.y * 8)
            return { door_origin, door_origin + v2.mk(8 - 1, 8 - 1) }
        end

        r.get_room_rect = function(self, door)
            return { self.v2_pos(self), self.v2_pos(self) + v2.mk(r.cols * 8, r.rows * 8) }
        end

        r.is_at_door = function(self, p1)
            p1_rect = p1.get_rect(p1)

            for door in all(self.doors) do
                local door_rect = self.get_door_rect(self, door)
                if utils.rect_col(door_rect[1], door_rect[2], p1_rect[1], p1_rect[2]) then
                    return door
                end
            end

            return nil
        end

        return r
    end,

    generate_doors = function(rm, num_doors)
        -- Generate the doors
        local doors = {}
        while #doors < num_doors do
            if flr(rnd(2)) == 1 then
                if flr(rnd(2)) == 1 then
                    x = 0
                else
                    x = rm.cols - 1
                end
                y = flr(rnd(rm.rows))
            else
                if flr(rnd(2)) == 1 then
                    y = 0
                else
                    y = rm.rows - 1
                end
                x = flr(rnd(rm.cols))
            end

            local new_door = v2.mk(x, y)
            local door_exists = false
            for d in all(doors) do
                if new_door.x == d.x and new_door.y == d.y then
                    door_exists = true
                    break
                end
            end

            if not door_exists then
                add(doors, new_door)
            end
        end

        rm.doors = doors
    end
}

return room
