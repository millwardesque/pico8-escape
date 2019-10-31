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
package._c["level"]=function()
local level = {
    mk = function()
        local l = {
        }

        return l
    end,
}

return level
end
package._c["obstacle"]=function()
game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local obstacle = {
    mk = function(x, y, width, height, sprite)
        local o = game_obj.mk('obstacle', 'obstacle', x, y)
        o.width = width
        o.height = height
        o.vel = v2.zero()

        renderer.attach(o, sprite)
        o.renderable.draw_order = 10

        o.get_rect = function(self)
            return { self.v2_pos(self), self.v2_pos(self) + v2.mk(self.width - 1, self.height - 1) }
        end

        o.get_centre = function(self)
            return v2.mk(self.x + self.width / 2, self.y + self.height / 2)
        end

        o.update = function(self)
            self.x += self.vel.x
            self.y += self.vel.y
        end

        return o
    end
}

return obstacle
end
package._c["player"]=function()
game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local player = {
    mk = function(x, y, sprite)
        local p = game_obj.mk('player', 'player', x, y)

        p.w = 8
        p.h = 8
        p.sprite = sprite
        p.vel = v2.zero()
        p.last_pos = v2.zero()
        p.max_stamina = 100
        p.stamina = 100


        renderer.attach(p, sprite)
        p.renderable.draw_order = 10

        p.get_rect = function(self)
            return { self.v2_pos(self), self.v2_pos(self) + v2.mk(self.w - 1, self.h - 1) }
        end

        p.get_last_rect = function(self)
            return { self.last_pos, self.last_pos + v2.mk(self.w - 1, self.h - 1) }
        end

        p.get_centre = function(self)
            return v2.mk(self.x + self.w / 2, self.y + self.h / 2)
        end

        p.update = function(self)
            self.last_pos = self.v2_pos(self)

            self.x += self.vel.x
            self.y += self.vel.y
        end

        p.injure = function(self, damage)
            self.max_stamina = max(0, self.max_stamina - damage)
            self.set_stamina(self, self.stamina)
        end

        p.set_stamina = function(self, new_stamina)
            self.stamina = min(self.max_stamina, max(0, new_stamina))
        end

        p.renderable.render = function(renderable, x, y)
            local go = renderable.game_obj
            renderable.default_render(renderable, x, y)

            -- Draw previous frame's rect
            local rect = go.get_last_rect(go)
            utils.draw_corners(rect)
        end

        return p
    end
}

return player
end
package._c["room"]=function()
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
        r.obstacles = {}

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

        -- log.syslog("SCORING: "..v2.str(my_coords)..": "..(g + h))
        return cell
    end,

    grid_coords = function(rm, world_pos)
        local lcl = world_pos - rm.v2_pos(rm)

        local grid_x = flr(lcl.x / 8)
        local grid_y = flr(lcl.y / 8)

        -- log.syslog("GC: "..v2.str(world_pos).." in "..v2.str(rm.v2_pos(rm)).." = LCL "..v2.str(lcl).." = GC "..v2.str(v2.mk(grid_x, grid_y)))

        return v2.mk(grid_x, grid_y)
    end,

    world_pos = function(rm, grid_coords)
        return rm.v2_pos(rm) + v2.mk((grid_coords.x) * 8, (grid_coords.y) * 8)
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
end
package._c["utils"]=function()
log = require('log')
v2 = require('v2')

local utils = {
    rnd_v2_near = function(x, y, min_dist, zone_size)
        local angle = rnd(1.0)
        local dist = min_dist + flr(rnd(zone_size / 2.0))
        local x = x + dist * cos(angle)
        local y = y + dist * sin(angle)
        return v2.mk(x, y)
    end,

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

    bool_str = function(b)
        if b then
            return "t"
        else
            return "f"
        end
    end,
}

return utils
end
package._c["villain"]=function()
game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local villain = {
    mk = function(x, y, sprite, target, speed)
        local v = game_obj.mk('villain', 'villain', x, y)

        v.w = 8
        v.h = 8
        v.sprite = sprite
        v.target = target
        v.path = nil
        v.speed = speed
        v.state = "hiding"
        v.stun_length = 0
        v.stun_elapsed = 0
        v.path_index = nil
        v.hiding_distance = 30

        v.last_pos = v2.zero()
        v.vel = v2.zero()

        renderer.attach(v, sprite)
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
            local push_vec = self.dir_to_point(self, self.target.v2_pos(self.target)) * -1 * push_amount
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
                        self.vel = self.dir_to_point(self, self.target.v2_pos(self.target)) * self.speed
                    else
                        local rect = self.get_rect(self)
                        if utils.pt_in_rect(self.path[self.path_index], rect[1], rect[2]) then
                            self.path_index += 1
                        end

                        if self.path_index > #(self.path) then
                            self.vel = self.dir_to_point(self, self.target.v2_pos(self.target)) * self.speed
                        else
                            self.vel = self.dir_to_point(self, self.path[self.path_index]) * self.speed
                        end
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

            self.last_pos = self.v2_pos(self)
            self.x += self.vel.x
            self.y += self.vel.y
        end

        v.get_rect = function(self)
            return { self.v2_pos(self), self.v2_pos(self) + v2.mk(self.w - 1, self.h - 1) }
        end

        v.get_last_rect = function(self)
            return { self.last_pos, self.last_pos + v2.mk(self.w - 1, self.h - 1) }
        end

        v.get_centre = function(self)
            return v2.mk(self.x + self.w / 2, self.y + self.h / 2)
        end

        return v
    end
}

return villain
end
package._c["ui"]=function()
local ui = {
    render_stamina = function(current, max)
        container_margin = 4
        container_width = 128 - (container_margin * 2)
        px_per_stamina = container_width / 100
        h = 5
        x0 = container_margin
        y = 127 - h - container_margin
        x1 = container_margin + (max * px_per_stamina)
        pct = (x1 - 1 - x0 - 1) * (current / max)
        current_x0 = x0 + 1
        current_x1 = x0 + 1 + pct

        rectfill(x0, y, x1, y + h, 14)
        rectfill(current_x0, y + 1, current_x1, y + h - 1, 8)
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
game_obj = require('game_obj')
log = require('log')
renderer = require('renderer')
v2 = require('v2')

level = require('level')
obstacle = require('obstacle')
player = require('player')
room = require('room')
utils = require('utils')
villain = require('villain')
ui = require('ui')

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

background = {x = 0, y = 0, w = 16, h = 16}

scene = nil
state = "ingame"


function next_level()
    active_level_index = (active_level_index % #levels) + 1
    active_level = levels[active_level_index]

    scene = {}

    cam = game_cam.mk("main-cam", 0, 0, 128, 128, 16, 16)
    add(scene, cam)

    -- Generate the room
    local cols = 12
    local rows = 6
    local spritesheet_index = 64
    local x_offset = 64 - (cols * 8) / 2
    local y_offset = 64 - (rows * 8) / 2

    -- Generate some obstacles
    local num_obstacles = 5
    obstacles = {}
    for i=1,num_obstacles do

        -- Generate coords inside the room
        local x = x_offset + (1 + flr(rnd(cols - 1))) * 8
        local y = y_offset + (1 + flr(rnd(rows - 1))) * 8

        local o = obstacle.mk(x, y, 8, 8, 128)
        add(obstacles, o)
        add(scene, o)
    end

    level_room = room.mk(x_offset, y_offset, cols, rows, spritesheet_index)
    level_room.obstacles = obstacles

    -- Generate the doors
    local num_doors = 2
    room.generate_doors(level_room, num_doors)
    add(scene, level_room)

    -- Add the player, and position on a door
    if p1 == nil then
        p1 = player.mk(0, 0, 1)
    end

    p1_start_cell = level_room.doors[1]
    local p1_pos = room.world_pos(level_room, p1_start_cell)
    p1.x = p1_pos.x
    p1.y = p1_pos.y
    add(scene, p1)
    are_doors_active = false

    -- Add the villain
    v1 = villain.mk(x_offset + level_room.doors[2].x * 8, y_offset + level_room.doors[2].y * 8, 32, p1, v1_speed)
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

        log.log("P1:"..v2.str(p1.v2_pos(p1)).." / "..v2.str(room.grid_coords(level_room, p1.v2_pos(p1))))

        if p1.stamina <= 0 then
            state = "gameover"
        elseif are_doors_active and not is_p1_caught() and level_room.is_at_door(level_room, p1) then   -- Check if the player is at a door
            state = "complete"
        end
    elseif state == "complete" then
        scene = {}
        if btnp(4) then
            next_level()
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
    cls(0)

    renderer.render(cam, scene, background)

    if state == "ingame" then
        log.log("Timer: "..flr(level_timer / stat(8)))
        ui.render_stamina(p1.stamina, p1.max_stamina)

        -- @DEBUG log.log("Mem: "..(stat(0)/2048.0).."% CPU: "..(stat(1)/1.0).."%")
    elseif state == "complete" then
        color(7)
        log.log("level complete!")
        log.log("press 4 for next level")
    elseif state == "gameover" then
        color(7)
        log.log("game over!")
        log.log("levels completed: "..levels_completed)
        log.log("press 4 to try again")
    end

    log.render()
end
__gfx__
00dddd0000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5555555bbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555b333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555b333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555b333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555b333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555b333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555b333333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555bbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44555544000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45455454000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45544554000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45544554000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45455454000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44555544000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

