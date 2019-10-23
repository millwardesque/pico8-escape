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

        r.is_walkable = function(self, grid_coord)
            -- @TODO Add obstacles to room
            return true
        end

        return r
    end,

    find_path = function(rm, origin, dest)
        local open = {}
        local closed = {}
        local grid_origin = room.grid_coords(rm, origin)
        local grid_dest = room.grid_coords(rm, dest)
        local path_complete = false

        local path_grid = {}
        for r=1,rm.rows do
            add(path_grid, {})
            for c=1,rm.cols do
                path_grid[r][c] = nil
            end
        end

        add(open, grid_origin)
        path_grid[grid_origin.y][grid_origin.x] = room.score_cell(grid_origin, nil, grid_dest)

        while (not path_complete and #open > 0) do
            log.syslog("*** ITERATION (o="..#open..", c="..#closed..") ***")
            local best_score = nil
            local best_cell = nil
            for c in all(open) do
                if c.x == dest.x and c.y == dest.y then
                    path_complete = true
                    add(closed, c)
                    break
                end

                local scored_cell = path_grid[c.y][c.x]
                local score = scored_cell.g + scored_cell.h

                -- log.syslog("I: "..v2.str(c).." S:"..score.." G:"..scored_cell.g.." H:"..scored_cell.h)
                if best_score == nil or score <= best_score then
                    best_cell = c
                    best_score = score

                    -- log.syslog("BEST: "..v2.str(c).." ("..best_score..")")
                end
            end

            if not path_complete then
                del(open, best_cell)
                add(closed, best_cell)

                room.check_cell(rm, path_grid, best_cell + v2.mk(-1, 0), path_grid[best_cell.y][best_cell.x], grid_dest, open, closed)
                room.check_cell(rm, path_grid, best_cell + v2.mk(1, 0), path_grid[best_cell.y][best_cell.x], grid_dest, open, closed)
                room.check_cell(rm, path_grid, best_cell + v2.mk(0, -1), path_grid[best_cell.y][best_cell.x], grid_dest, open, closed)
                room.check_cell(rm, path_grid, best_cell + v2.mk(0, 1), path_grid[best_cell.y][best_cell.x], grid_dest, open, closed)
            end
        end

        if path_complete then
            local path = {}

            for i=#closed,1 do
                add(path, closed[i])
            end
            return path
        else
            return nil
        end
    end,

    check_cell = function(rm, path_grid, my_coords, parent, grid_dest, open, closed)
        -- log.syslog("CHECKING: "..v2.str(my_coords).." TO "..v2.str(grid_dest))
        if my_coords.x < 1 or my_coords.x > rm.cols or
            my_coords.y < 1 or my_coords.y > rm.rows then
                return

        --         log.syslog("...NOT IN BOUNDS")
        end

        if not rm.is_walkable(rm, my_coords) then
        --     log.syslog("...NOT WALKABLE")
            return
        end

        for c in all(closed) do
            if c.x == my_coords.x and c.y == my_coords.y then
        --         log.syslog("...IN CLOSED ALREADY")
                return
            end
        end

        local is_in_open = false
        for c in all(open) do
            if c.x == my_coords.x and c.y == my_coords.y then
                is_in_open = true
                break
            end
        end

        if not is_in_open then
        --     log.syslog("...NOT IN OPEN")
            add(open, my_coords)
            path_grid[my_coords.y][my_coords.x] = room.score_cell(my_coords, parent, grid_dest)
        else
        --     log.syslog("...IN OPEN ALREADY. COMPARING.")
            local current_score = path_grid[my_coords.y][my_coords.x]
            local current_f = current_score.g + current_score.h

            local new_score = room.score_cell(my_coords, parent, grid_dest)
            local new_f = new_score.g + new_score.h

            if new_f <= current_f then
                path_grid[my_coords.y][my_coords.x] = new_score
            end
        end
    end,

    score_cell = function(my_coords, parent, target_coords)
        log.syslog("SCORING: "..v2.str(my_coords).." vs. "..v2.str(target_coords))
        local g = 0
        if parent then
            g = parent.g + 1
        end

        local h = abs(target_coords.x - my_coords.x) + abs(target_coords.y - my_coords.y)

        local cell = {
            coords = my_coords,
            parent = parent,
            g = g,
            h = h
        }
        return cell
    end,

    grid_coords = function(rm, world_pos)
        local lcl = world_pos - rm.v2_pos(rm)

        local grid_x = flr(lcl.x / 8) + 1
        local grid_y = flr(lcl.y / 8) + 1

        log.syslog("GC: "..v2.str(world_pos).." in "..v2.str(rm.v2_pos(rm)).." = LCL "..v2.str(lcl).." = GC "..v2.str(v2.mk(grid_x, grid_y)))

        return v2.mk(grid_x, grid_y)
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
