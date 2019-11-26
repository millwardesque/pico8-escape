pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
package={loaded={},_c={}}
package._c["game_cam"]=function()
game_obj = require('game_obj')

local game_cam = {
    mk = function(name, pos_x, pos_y, width, height, bounds_x, bounds_y)
        local c = game_obj.mk(name, 'camera', pos_x, pos_y)
        c.cam = {
            w = width,
            h = height,
            bounds_x = bounds_x,
            bounds_y = bounds_y,
            target = nil,
        }

        c.update = function(cam)
            -- Track a target
            target = cam.cam.target
            if target ~= nil then
                if target.x < cam.x + cam.cam.bounds_x then
                    cam.x = target.x - cam.cam.bounds_x
                elseif target.x > cam.x + cam.cam.w - cam.cam.bounds_x then
                    cam.x = target.x - cam.cam.w + cam.cam.bounds_x
                end

                if target.y < cam.y + cam.cam.bounds_y then
                    cam.y = target.y - cam.cam.bounds_y
                elseif target.y > cam.y + cam.cam.h - cam.cam.bounds_y then
                    cam.y = target.y - cam.cam.h + cam.cam.bounds_y
                end
            end

            -- Prevent camera from scrolling off the top-left side of the map
            if cam.x < 0 then cam.x = 0 end
            if cam.y < 0 then cam.y = 0 end
        end

        return c
    end,
    draw_start = function (cam)
        camera(cam.x, cam.y)
        clip(0, 0, cam.cam.w, cam.cam.h)
    end,
    draw_end = function(cam)
        camera()
        clip()
    end,
}
return game_cam
end
package._c["game_obj"]=function()
v2 = require('v2')

local game_obj = {
    mk = function(name, type, pos_x, pos_y)
        local g = {
            name = name,
            type = type,
            x = pos_x,
            y = pos_y,
        }
        g.update = function(self)
        end

        g.v2_pos = function(self)
            return v2.mk(self.x, self.y)
        end

        return g
    end,

    pos = function(go)
        return v2.mk(go.x, go.y)
    end
}
return game_obj
end
package._c["v2"]=function()
local v2 = {
    mk = function(x, y)
        local v = {x = x, y = y,}
        setmetatable(v, v2.meta)
        return v;
    end,
    clone = function(x, y)
        return v2.mk(v.x, v.y)
    end,
    zero = function()
        return v2.mk(0, 0)
    end,
    mag = function(v)
        if v.x == 0 and v.y == 0 then
            return 0
        else
            return sqrt(v.x ^ 2 + v.y ^ 2)
        end
    end,
    norm = function(v)
        local m = v2.mag(v)
        if m == 0 then
            return v
        else
            return v2.mk(v.x / m, v.y / m)
        end
    end,
    str = function(v)
        if v == nil then
            return "(nil)"
        else
            return "("..v.x..", "..v.y..")"
        end
    end,
    meta = {
        __add = function (a, b)
            return v2.mk(a.x + b.x, a.y + b.y)
        end,

        __sub = function (a, b)
            return v2.mk(a.x - b.x, a.y - b.y)
        end,

        __mul = function (a, b)
            if type(a) == "number" then
                return v2.mk(a * b.x, a * b.y)
            elseif type(b) == "number" then
                return v2.mk(b * a.x, b * a.y)
            else
                return v2.mk(a.x * b.x, a.y * b.y)
            end
        end,

        __div = function(a, b)
            v2.mk(a.x / b, a.y / b)
        end,

        __eq = function (a, b)
            return a.x == b.x and a.y == b.y
        end,
    },
}
return v2
end
package._c["log"]=function()
local log = {
    debug = true,
    file = 'debug.log',
    _data = {},

    log = function(msg)
        add(log._data, msg)
    end,
    syslog = function(msg)
        printh(msg, log.file)
    end,
    render = function()
        if log.debug then
            color(7)
            for i = 1, #log._data do
                print(log._data[i], 5, 5 + (8 * (i - 1)))
            end
        end

        log._data = {}
    end,
    tostring = function(any)
        if type(any)=="function" then
            return "function"
        end
        if any==nil then
            return "nil"
        end
        if type(any)=="string" then
            return any
        end
        if type(any)=="boolean" then
            if any then return "true" end
            return "false"
        end
        if type(any)=="table" then
            local str = "{ "
            for k,v in pairs(any) do
                str=str..log.tostring(k).."->"..log.tostring(v).." "
            end
            return str.."}"
        end
        if type(any)=="number" then
            return ""..any
        end
        return "unkown" -- should never show
    end
}
return log
end
package._c["renderer"]=function()
log = require('log')

local renderer = {
    render = function(cam, scene, bg)
        -- Collect renderables
        local to_render = {};
        for obj in all(scene) do
            if (obj.renderable) then
                if obj.renderable.enabled then
                    add(to_render, obj)
                end
            end
        end

        -- Sort
        renderer.sort(to_render)

        -- Draw
        game_cam.draw_start(cam)

        if bg then
            map(bg.x, bg.y, 0, 0, bg.w, bg.h)
        end

        for obj in all(to_render) do
            obj.renderable.render(obj.renderable, obj.x, obj.y)
        end

        game_cam.draw_end(cam)
    end,

    attach = function(game_obj, sprite)
        local r = {
            game_obj = game_obj,
            sprite = sprite,
            flip_x = false,
            flip_y = false,
            w = 1,
            h = 1,
            draw_order = 0,
            palette = nil,
            enabled = true
        }

        -- Default rendering function
        r.render = function(self, x, y)
            -- Set the palette
            if (self.palette) then
                -- Set colours
                for i = 0, 15 do
                    pal(i, self.palette[i + 1])
                end

                -- Set transparencies
                for i = 17, #self.palette do
                    palt(self.palette[i], true)
                end
            end

            -- Draw
            spr(self.sprite, x, y, self.w, self.h, self.flip_x, self.flip_y)

            -- Reset the palette
            if (self.palette) then
                pal()
            end
        end

        -- Save the default render function in case the obj wants to use it in an overridden render function.
        r.default_render = r.render

        game_obj.renderable = r;
        return game_obj;
    end,

    -- Sort a renderable array by draw-order
    sort = function(list)
        renderer.sort_helper(list, 1, #list)
    end,
    -- Helper function for sorting renderables by draw-order
    sort_helper = function (list, low, high)
        if (low < high) then
            local p = renderer.sort_split(list, low, high)
            renderer.sort_helper(list, low, p - 1)
            renderer.sort_helper(list, p + 1, high)
        end
    end,
    -- Partition a renderable list by draw_order
    sort_split = function (list, low, high)
        local pivot = list[high]
        local i = low - 1
        local temp
        for j = low, high - 1 do
            if (list[j].renderable.draw_order < pivot.renderable.draw_order or
                (list[j].renderable.draw_order == pivot.renderable.draw_order and list[j].y < pivot.y)) then
                i += 1
                temp = list[j]
                list[j] = list[i]
                list[i] = temp
            end
        end

        if (list[high].renderable.draw_order < list[i + 1].renderable.draw_order or
            (list[high].renderable.draw_order == list[i + 1].renderable.draw_order and list[high].y < list[i + 1].y)) then
            temp = list[high]
            list[high] = list[i + 1]
            list[i + 1] = temp
        end

        return i + 1
    end
}
return renderer
end
package._c["obstacle"]=function()
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
end
package._c["actor"]=function()
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
            if self.current_anim != nil then
                self.anim_frame_count = (self.anim_frame_count + 1) % FRAME_LEN
                if self.anim_frame_count == 0 then
                    self.anim_frame_index = (self.anim_frame_index + 1) % #self.current_anim
                    self.renderable.sprite = self.current_anim[self.anim_frame_index + 1]
                end
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
end
package._c["player"]=function()
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
end
package._c["room"]=function()
game_obj = require('game_obj')
log = require('log')
renderer = require('renderer')
utils = require('utils')

local room = {
    mk = function(x, y, cols, rows, tileset, fog_target, fog_distance)
        local r = game_obj.mk('room', 'room', x, y)
        r.cols = cols
        r.rows = rows
        r.tileset = tileset
        r.doors = {}
        r.obstacles = {}
        r.fog_target = fog_target
        r.fog_distance = fog_distance

        renderer.attach(r, tileset)

        r.renderable.render = function(renderable, x, y)
            local go = renderable.game_obj

            -- Draw floors
            local fog = room.fog_cells(go, game_obj.pos(go.fog_target), go.fog_distance)
            for col=0, go.cols - 1 do
                for row=0, go.rows - 1 do
                    if utils.is_in_table(fog, v2.mk(col, row)) then
                        renderable.sprite = go.tileset
                    else
                        renderable.sprite = go.tileset + 1
                    end
                    renderable.default_render(renderable, x + col * 8, y + row * 8)
                end
            end

            -- Draw wall
            local wall_x = x - 8
            local wall_y = y - 8

            -- Top and bottom walls
            for col=0, go.cols + 1 do
                renderable.sprite = go.tileset + 19
                renderable.default_render(renderable, wall_x + col * 8, wall_y)

                renderable.sprite = go.tileset + 17
                renderable.default_render(renderable, wall_x + col * 8, wall_y + (go.rows + 1) * 8)
            end

            -- Left and right walls
            for row=0, go.rows + 1 do
                renderable.sprite = go.tileset + 16
                renderable.default_render(renderable, wall_x, wall_y + row * 8)

                renderable.sprite = go.tileset + 18
                renderable.default_render(renderable, wall_x + (go.cols + 1) * 8, wall_y + row * 8)
            end

            -- Draw doors
            renderable.sprite = go.tileset + 32
            local obstacle_fog = room.fog_cells(go, game_obj.pos(go.fog_target), go.fog_distance + 1)
            for door in all(go.doors) do
                if utils.is_in_table(obstacle_fog, door) then
                    renderable.default_render(renderable, x + door.x * 8, y + door.y * 8)
                end
            end

            -- Draw obstacles
            for obs in all(go.obstacles) do
                local obs_grid = room.grid_coords(go, game_obj.pos(obs))
                if utils.is_in_table(obstacle_fog, obs_grid) then
                    renderable.sprite = obs.sprite
                    renderable.default_render(renderable, obs.x, obs.y)
                end
            end

            -- Draw door collider corners
            -- for door in all(go.doors) do
            --     door_rect = go.get_door_rect(go, door)
            --     utils.draw_corners(door_rect)
            -- end
        end

        r.get_door_rect = function(self, door)
            local origin = game_obj.pos(self) + v2.mk(door.x * 8, door.y * 8)
            return { origin, origin + v2.mk(8 - 1, 8 - 1) }
        end

        r.get_room_rect = function(self, door)
            return { game_obj.pos(self), game_obj.pos(self) + v2.mk(r.cols * 8, r.rows * 8) }
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
            local walkable = true
            -- log.syslog("Checking "..v2.str(grid_coord))
            for o in all(self.obstacles) do
                local obj_rect = o.get_rect(o)
                -- @DEBUG log.syslog(o.name..": "..v2.str(obj_rect[1]).." to "..v2.str(obj_rect[2]))

                local obj_grid_coords = {
                    room.grid_coords(self, obj_rect[1]),
                    room.grid_coords(self, v2.mk(obj_rect[1].x, obj_rect[2].y)),
                    room.grid_coords(self, v2.mk(obj_rect[2].x, obj_rect[1].y)),
                    room.grid_coords(self, obj_rect[2]),
                }

                for og in all(obj_grid_coords) do
                    if grid_coord == og then
                        walkable = false
                        break
                    end
                end
            end

            return walkable
        end

        return r
    end,

    fog_cells = function(rm, origin, fog_range)
        local grid_0 = room.grid_coords(rm, origin)
        local cells = {}

        log.log("g: "..v2.str(grid_0).." p: "..v2.str(origin))

        for col=-fog_range,fog_range do
            for row=-fog_range,fog_range do
                local coord = v2.mk(col + grid_0.x, row + grid_0.y)
                if coord.y >= 0 and coord.y < rm.rows and coord.x >= 0 and coord.x < rm.cols then
                    add(cells, coord)
                end
            end
        end

        return cells
    end,

    find_path = function(rm, origin, dest)
        local open = {}
        local closed = {}
        local grid_origin = room.grid_coords(rm, origin)
        local grid_dest = room.grid_coords(rm, dest)
        local path_complete = false

        -- log.syslog("Start=>End: "..v2.str(grid_origin).." to "..v2.str(grid_dest))

        local path_grid = {}
        for r=1,rm.rows do
            add(path_grid, {})
            for c=1,rm.cols do
                path_grid[r][c] = nil
            end
        end

        add(open, grid_origin)
        path_grid[grid_origin.y + 1][grid_origin.x + 1] = room.score_cell(grid_origin, nil, grid_dest)

        while (not path_complete and #open > 0) do
            -- log.syslog("*** ITERATION (o="..#open..", c="..#closed..") ***")
            local best_score = nil
            local best_cell = nil
            for c in all(open) do
                if c.x == grid_dest.x and c.y == grid_dest.y then
                    -- log.syslog("FOUND ROUTE")
                    path_complete = true
                    add(closed, c)
                    break
                end

                local scored_cell = path_grid[c.y + 1][c.x + 1]
                local score = scored_cell.g + scored_cell.h

                -- log.syslog("I: "..v2.str(c).." S:"..score.." G:"..scored_cell.g.." H:"..scored_cell.h)
                if best_score == nil or score <= best_score then
                    best_cell = c
                    best_score = score

                    -- log.syslog("BEST: "..v2.str(c).." ("..best_score..")")
                end
            end

            if not path_complete then
                -- log.syslog("Chose "..v2.str(best_cell))
                del(open, best_cell)
                add(closed, best_cell)

                room.check_cell(rm, path_grid, best_cell + v2.mk(-1, 0), path_grid[best_cell.y + 1][best_cell.x + 1], grid_dest, open, closed)
                room.check_cell(rm, path_grid, best_cell + v2.mk(1, 0), path_grid[best_cell.y + 1][best_cell.x + 1], grid_dest, open, closed)
                room.check_cell(rm, path_grid, best_cell + v2.mk(0, -1), path_grid[best_cell.y + 1][best_cell.x + 1], grid_dest, open, closed)
                room.check_cell(rm, path_grid, best_cell + v2.mk(0, 1), path_grid[best_cell.y + 1][best_cell.x + 1], grid_dest, open, closed)
            end
        end

        if path_complete then
            local path = {}
            local reverse_path = {}
            local node = path_grid[closed[#closed].y + 1][closed[#closed].x + 1]

            while (node != nil) do
                add(reverse_path, room.world_pos(rm, node.coords) + v2.mk(4, 4))
                node = node.parent
            end

            -- Ignore start point
            for i = #reverse_path - 1,2,-1 do
                add(path, reverse_path[i])
            end
            add(path, dest)
            return path
        else
            return nil
        end
    end,

    check_cell = function(rm, path_grid, my_coords, parent, grid_dest, open, closed)
        -- log.syslog("CHECKING: "..v2.str(my_coords).." TO "..v2.str(grid_dest))
        if my_coords.x < 0 or my_coords.x >= rm.cols or
            my_coords.y < 0 or my_coords.y >= rm.rows then
                return
        -- log.syslog("...NOT IN BOUNDS")
        end

        if not rm.is_walkable(rm, my_coords) then
            -- log.syslog("...NOT WALKABLE")
            return
        end

        for c in all(closed) do
            if c.x == my_coords.x and c.y == my_coords.y then
                -- log.syslog("...IN CLOSED ALREADY")
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
            -- log.syslog("...NOT IN OPEN")
            add(open, my_coords)
            path_grid[my_coords.y + 1][my_coords.x + 1] = room.score_cell(my_coords, parent, grid_dest)
        else
            -- log.syslog("...IN OPEN ALREADY. COMPARING.")
            local current_score = path_grid[my_coords.y + 1][my_coords.x + 1]
            local current_f = current_score.g + current_score.h

            local new_score = room.score_cell(my_coords, parent, grid_dest)
            local new_f = new_score.g + new_score.h

            if new_f <= current_f then
                path_grid[my_coords.y + 1][my_coords.x + 1] = new_score
            end
        end
    end,

    score_cell = function(my_coords, parent, target_coords)
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
        local lcl = world_pos - game_obj.pos(rm)

        local grid_x = flr(lcl.x / 8)
        local grid_y = flr(lcl.y / 8)

        return v2.mk(grid_x, grid_y)
    end,

    world_pos = function(rm, grid_coords)
        return game_obj.pos(rm) + v2.mk((grid_coords.x) * 8, (grid_coords.y) * 8)
    end,

    cell_rect = function(rm, coords)
        local world_coords = room.world_pos(rm, coords)
        local rect = {
            world_coords,
            world_coords + v2.mk(8 - 1, 8 - 1),
        }
        return rect
    end,

    generate_doors = function(rm, num_doors)
        -- Generate the doors
        rm.doors = {}
        while #rm.doors < num_doors do
            local door = utils.rnd_outer_grid(rm.rows, rm.cols)
            local door_exists = false
            for d in all(rm.doors) do
                if door.x == d.x and door.y == d.y then
                    door_exists = true
                    break
                end
            end

            if door_exists == false then
                add(rm.doors, door)
            end
        end
    end
}

return room
end
package._c["utils"]=function()
log = require('log')
v2 = require('v2')

local utils = {
    circle_col = function(p1, r1, p2, r2)
        local dist = v2.mag(p2 - p1)
        if dist < 0 then
            -- Negative distance implies int overflow, so clearly the distance is farther than we can track.
            return nil
        elseif dist < (r1 + r2) then
            return true
        else
            return false
        end
    end,

    pt_in_rect = function(p, tl, br)
        return (p.x >= tl.x and
                p.x <= br.x and
                p.y >= tl.y and
                p.y <= br.y)
    end,

    rect_col = function(p0tl, p0br, p1tl, p1br)
        return p0tl.x <= p1br.x and
               p0br.x >= p1tl.x and
               p0tl.y <= p1br.y and
               p0br.y >= p1tl.y
    end,

    draw_corners = function(rect)
        pset(rect[1].x, rect[1].y)
        pset(rect[2].x, rect[1].y)
        pset(rect[2].x, rect[2].y)
        pset(rect[1].x, rect[2].y)
    end,

    is_in_table = function(t, o)
        for i in all(t) do
            if i == o then
                return true
            end
        end

        return false
    end,

    bool_str = function(b)
        if b then
            return "t"
        else
            return "f"
        end
    end,

    rnd_outer_grid = function(rows, cols)
        local x
        local y

        if flr(rnd(2)) == 1 then
            if flr(rnd(2)) == 1 then
                x = 0
            else
                x = cols - 1
            end
            y = flr(rnd(rows))
        else
            if flr(rnd(2)) == 1 then
                y = 0
            else
                y = rows - 1
            end
            x = flr(rnd(cols))
        end

        return v2.mk(x, y)
    end,
}

return utils
end
package._c["villain"]=function()
actor = require('actor')
game_obj  = require('game_obj')

local villain = {
    mk = function(x, y, sprite, target, speed)
        local anims = {}
        anims['walk'] = {sprite, sprite + 1, sprite + 2, sprite + 3}

        local v = actor.mk('villain', 'villain', x, y, sprite, anims)

        v.target = target
        v.path = nil
        v.speed = speed
        v.state = "hiding"
        v.stun_length = 0
        v.stun_elapsed = 0
        v.path_index = nil
        v.hiding_distance = 30
        v.set_anim(v, 'walk')

        v.renderable.draw_order = 10

        v.renderable.render = function(self, x, y)
            local go = self.game_obj

            if go.state != "hiding" then
                self.default_render(self, x, y)
            end

            if go.state == "pursuit" and go.path != nil then
                local path = self.game_obj.path
                for i=1,#path do
                    if i < self.game_obj.path_index then
                        color(5)
                    else
                        color(7)
                    end
                    circfill(path[i].x, path[i].y, 0.5)
                end
            end
        end

        v.set_path = function(self, new_path)
            self.path = new_path
            self.path_index = 1
        end

        v.dislodge = function(self, p1, push_amount, stun_length)
            -- Push away from target back
            local push_vec = self.dir_to_point(self, game_obj.pos(self.target)) * -1 * push_amount
            self.x += push_vec.x
            self.y += push_vec.y

            self.state = "stunned"
            self.stun_length = stun_length
        end

        v.dir_to_point = function(self, point)
            local d = point - self.get_centre(self)
            return v2.norm(d)
        end

        v.dist_to_point = function(self, point)
            local d = point - self.get_centre(self)
            return v2.mag(d)
        end

        v.is_stunned = function(self)
            return self.state == "stunned"
        end

        v.update = function(self)
            if self.state == "pursuit" then
                if self.path != nil then
                    if self.path_index > #(self.path) then
                        self.vel = self.dir_to_point(self, game_obj.pos(self.target)) * self.speed
                    else
                        local rect = self.get_rect(self)
                        if utils.pt_in_rect(self.path[self.path_index], rect[1], rect[2]) then
                            self.path_index += 1
                        end

                        if self.path_index > #(self.path) then
                            self.vel = self.dir_to_point(self, game_obj.pos(self.target)) * self.speed
                        else
                            self.vel = self.dir_to_point(self, self.path[self.path_index]) * self.speed
                        end
                    end

                    if self.vel.x > 0 then
                        self.renderable.flip_x = false
                    elseif self.vel.x < 0 then
                        self.renderable.flip_x = true
                    end
                end
            elseif self.is_stunned(self) then
                self.stun_elapsed += 1
                self.vel = v2.zero()

                if self.stun_elapsed == self.stun_length then
                    self.stun_elapsed = 0
                    self.stun_length = 0
                    self.state = "pursuit"
                end
            elseif self.state == "hiding" then
                self.vel = v2.zero()
                if self.dist_to_point(self, self.target.get_centre(self.target)) < self.hiding_distance then
                    self.state = "pursuit"
                end
            end

            self.default_update(self)
        end

        return v
    end
}

return villain
end
package._c["ui"]=function()
local ui = {
    stamina = function(current, max)
        local margin = 4
        local w = 128 - (margin * 2)
        local h = 5
        local px_per_stamina = w / 100
        x0 = margin
        y = 127 - h - margin
        x1 = margin + (max * px_per_stamina)
        pct = (x1 - 1 - x0 - 1) * (current / max)

        rectfill(x0, y, x1, y + h, 14)
        rectfill(x0 + 1, y + 1, x0 + 1 + pct, y + h - 1, 8)
    end,

    horiz_wipe = function()
        local px_per_frame = 6
        for x=0, ceil(128 / px_per_frame) do
            rectfill(0, 0, x * px_per_frame, 127, 0)
            yield()
        end
    end
}
return ui
end
function require(p)
local l=package.loaded
if (l[p]==nil) l[p]=package._c[p]()
if (l[p]==nil) l[p]=true
return l[p]
end
game_cam = require('game_cam')
log = require('log')
renderer = require('renderer')
v2 = require('v2')

obstacle = require('obstacle')
player = require('player')
room = require('room')
utils = require('utils')
villain = require('villain')
ui = require('ui')

screen_wipe = nil

cam = nil
p1 = nil
p1_walk_speed = 1.6
p1_caught_speed = p1_walk_speed / 4
p1_run_speed = p1_walk_speed * 1.5
p1_caught_time = 0
injury_time = 20
injury_amount = 5
push_amount = 10
stun_length = 45
escape_amount = 0
escape_threshold = 5

v1 = nil
v1_speed = 1.5

level_timer = nil
level_room = nil
are_doors_active = false -- Doors become active once the player moves off the starting door
p1_start_cell = nil

active_level = nil
active_level_index = nil
levels = {}
levels_completed = 0
secs_per_level = 30
obstacles = {}

sky_colors = {0,1,2,13,14,9,6,12}
sky_step_length = flr(stat(8) * (secs_per_level + 1) / #sky_colors)
sky_frame_count = 0
sky_color_index = 0

background = {x = 0, y = 0, w = 16, h = 16}

scene = nil
state = "ingame"


function next_level()
    active_level_index = (active_level_index % #levels) + 1
    active_level = levels[active_level_index]

    scene = {}

    cam = game_cam.mk("main-cam", 0, 0, 128, 128, 16, 16)
    add(scene, cam)

    -- Define the player
    if p1 == nil then
        p1 = player.mk(0, 0, 0)
    end

    -- Generate the room
    local cols = 5 + flr(rnd(8))
    local rows = 5 + flr(rnd(8))
    local spritesheet_index = 64
    local x_offset = 64 - (cols * 8) / 2
    local y_offset = 64 - (rows * 8) / 2

    -- Generate some obstacles
    local num_obstacles = 5
    obstacles = {}
    for i=1,num_obstacles do

        -- Generate coords inside the room
        local x = x_offset + (1 + flr(rnd(cols - 2))) * 8
        local y = y_offset + (1 + flr(rnd(rows - 2))) * 8

        local o = obstacle.mk(x, y, 8, 8, 128)
        add(obstacles, o)
        add(scene, o)
    end

    level_room = room.mk(x_offset, y_offset, cols, rows, spritesheet_index, p1, 1)
    level_room.obstacles = obstacles

    -- Generate the doors
    local num_doors = 2
    room.generate_doors(level_room, num_doors)
    add(scene, level_room)

    -- Position player on a door
    p1_start_cell = level_room.doors[1]
    local p1_pos = room.world_pos(level_room, p1_start_cell)
    p1.x = p1_pos.x
    p1.y = p1_pos.y
    add(scene, p1)
    are_doors_active = false

    -- Add the villain
    local v1_start_cell = utils.rnd_outer_grid(rows, cols)
    local v1_start = room.world_pos(level_room, v1_start_cell)
    v1 = villain.mk(v1_start.x, v1_start.y, 32, p1, v1_speed)
    add(scene, v1)

    v1.set_path(v1, room.find_path(level_room, v1.get_centre(v1), p1.get_centre(p1)))

    if level_timer == nil then
        level_timer = secs_per_level * stat(8)
    end

    state = "ingame"

    -- log.syslog("Starting!")
    -- local testpath = room.find_path(level_room, v2.mk(56, 64), v2.mk(96, 64))
    -- for p in all(testpath) do
    --     log.syslog(v2.str(p))
    -- end
    -- log.syslog("Done!")
end

function restart_level()
    active_level_index -= 1
    next_level()
end

function reset_game()
    active_level_index = 0
    levels_completed = 0
    p1 = nil
    v1 = nil
    level_timer = nil
    sky_color_index = 0
    sky_frame_count = 0

    next_level()
end

function _init()
    log.debug = true

    reset_game()
end

function bool_str(b)
    if b then
        return "true"
    else
        return "false"
    end
end

function is_p1_caught()
    return p1_caught_time > 0
end

function _update()
    if state == "test" then
        test = 0
    elseif state == "ingame" then
        p1.vel = v2.zero()

        local p1_speed = 0
        if is_p1_caught() then
            p1_speed = p1_caught_speed
        elseif btn(5) and p1.stamina > 20 then
            p1_speed = p1_run_speed
            p1.set_stamina(p1, p1.stamina - 1)
        else
            p1_speed = p1_walk_speed
        end

        if btn(0) then
            p1.vel.x -= p1_speed
        end
        if btn(1) then
            p1.vel.x += p1_speed
        end

        if btn(2) then
            p1.vel.y -= p1_speed
        end
        if btn(3) then
            p1.vel.y += p1_speed
        end

        if btnp(5) then
            restart_level()
        end

        if is_p1_caught() then
            if btnp(4) then
                escape_amount += 1

                if escape_amount >= escape_threshold then
                    v1.dislodge(v1, p1, push_amount, stun_length)
                    escape_amount = 0
                end
            else
                escape_amount -= 0.01
            end
        end

        level_timer -= 1

        if level_timer == 0 then
            state = "gameover"
        end

        for obj in all(scene) do
            if obj.update then
                obj.update(obj)
            end
        end

        -- Adjust actors to be in room
        restrict_to_room(level_room, p1, 8, 8)
        restrict_to_room(level_room, v1, 8, 8)

        -- Collide with obstacles
        for o in all(obstacles) do
            collide_with_obstacle(p1, o, 8, 8)
            collide_with_obstacle(v1, o, 8, 8)
        end

        -- Check if the player has moved off the starting square
        local p1_rect = p1.get_rect(p1)
        local start_cell_rect = room.cell_rect(level_room, p1_start_cell)
        if false == are_doors_active and false == utils.rect_col(p1_rect[1], p1_rect[2], start_cell_rect[1], start_cell_rect[2]) then
            are_doors_active = true
        end

        p1_rect = p1.get_rect(p1)
        v1_rect = v1.get_rect(v1)
        if not v1.is_stunned(v1) and utils.rect_col(p1_rect[1], p1_rect[2], v1_rect[1], v1_rect[2]) then
            p1.set_stamina(p1, p1.stamina - 1)

            p1_caught_time += 1
            if p1_caught_time > injury_time then
                p1_caught_time -= injury_time
                p1.injure(p1, injury_amount)
            end
        else
            p1_caught_time = 0
            p1.set_stamina(p1, p1.stamina + 0.5)
        end

        -- @TODO This is out of place, but easiest for now
        if level_timer % flr(stat(8) / 4) == 0 then
            v1.set_path(v1, room.find_path(level_room, v1.get_centre(v1), p1.get_centre(p1)))
        end

        sky_frame_count += 1
        while sky_frame_count >= sky_step_length do
            sky_frame_count -= sky_step_length
            sky_color_index = (sky_color_index + 1) % #sky_colors
        end

        if p1.stamina <= 0 then
            state = "gameover"
        elseif are_doors_active and not is_p1_caught() and level_room.is_at_door(level_room, p1) then   -- Check if the player is at a door
            state = "complete"
            screen_wipe = cocreate(ui.horiz_wipe)
        end
    elseif state == "complete" then
        if costatus(screen_wipe) == 'dead' then
            next_level()
            screen_wipe = nil
        end
    elseif state == "gameover" then
        scene = {}
        if btnp(4) then
            reset_game()
        end
    end
end

function restrict_to_room(room, actor, actor_size_x, actor_size_y)
    local room_rect = room.get_room_rect(room)
    local actor_rect = actor.get_rect(actor)

    if actor_rect[1].x < room_rect[1].x then
        actor.x = room_rect[1].x
    end

    if actor_rect[2].x >= room_rect[2].x then
        actor.x = room_rect[2].x - actor_size_x
    end

    if actor_rect[1].y < room_rect[1].y then
        actor.y = room_rect[1].y
    end

    if actor_rect[2].y >= room_rect[2].y then
        actor.y = room_rect[2].y - actor_size_y
    end
end

function collide_with_obstacle(actor, obst, actor_size_x, actor_size_y)
    local obst_rect = obst.get_rect(obst)
    local actor_rect = actor.get_rect(actor)

    if utils.rect_col(actor_rect[1], actor_rect[2], obst_rect[1], obst_rect[2]) then
        local actor_last_rect = actor.get_last_rect(actor)
        local is_lhs = actor_last_rect[2].x < obst_rect[1].x
        local is_rhs = actor_last_rect[1].x > obst_rect[2].x
        local is_top = actor_last_rect[2].y < obst_rect[1].y
        local is_bottom = actor_last_rect[1].y > obst_rect[2].y

        if is_lhs and not is_rhs and not is_top and not is_bottom then
            actor.x = obst_rect[1].x - actor_size_x
        elseif is_rhs and not is_lhs and not is_top and not is_bottom then
            actor.x = obst_rect[2].x + 1
        elseif is_bottom and not is_top and not is_lhs and not is_rhs then
            actor.y = obst_rect[2].y + 1
        elseif is_top and not is_bottom and not is_lhs and not is_rhs then
            actor.y = obst_rect[1].y - actor_size_y
        end
    end
end

function _draw()
    cls(sky_colors[sky_color_index + 1])

    renderer.render(cam, scene, background)

    if state == "ingame" then
        log.log("Timer: "..flr(level_timer / stat(8)))
        ui.stamina(p1.stamina, p1.max_stamina)

        -- @DEBUG log.log("Mem: "..(stat(0)/2048.0).."% CPU: "..(stat(1)/1.0).."%")
    elseif state == "complete" then
        color(7)

        if costatus(screen_wipe) != 'dead' then
          coresume(screen_wipe)
        end
    elseif state == "gameover" then
        color(7)
        log.log("game over!")
        log.log("levels completed: "..levels_completed)
        log.log("press 4 to try again")
    end
    log.render()
end
__gfx__
0000000000bbb0000000000000bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbb00000bbbbb000bbb00000bbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbbb000ff1f0000bbbbb000ff1f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ff1f00000fff0000ff1f00000fff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000fff0000033000000fff0000033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b3000003b3000000b3000003b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0033bf00003b30000fb33500003b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06007000006f7000007060000067f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007760000000000000776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00776000007786000077600000778600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00778600007777600077860000777760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777760000778800077776000077880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077880000277600007788000027760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e7760002e2000000e7760002e2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0022e700002e200007e22600002e2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100d000001d700000d010000017d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055555555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000505505050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055050505055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000505000000005050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000505000000005050000050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055000000005500000005050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000505000000005050000055555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b3333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b333333b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b333333b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b333673b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b333333b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b333333b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66111166000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61611616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61166116000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61166116000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61611616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66111166000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
