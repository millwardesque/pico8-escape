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
        return "("..v.x..", "..v.y..")"
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
        p.sprite = sprite
        p.vel = v2.zero()
        p.max_stamina = 100
        p.stamina = 100

        renderer.attach(p, sprite)
        p.renderable.draw_order = 10

        p.get_rect = function(self)
            return { self.v2_pos(self), self.v2_pos(self) + v2.mk(8 - 1, 8 - 1) }
        end

        p.update = function(self)
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
end
package._c["room"]=function()
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

        r.get_room_rect = function(self, door)
            return { self.v2_pos(self), self.v2_pos(self) + v2.mk(r.x_dim * 8, r.y_dim * 8) }
        end

        r.is_at_door = function(self, p1)
            p1_rect = p1.get_rect(p1)

            for door in all(doors) do
                local door_rect = self.get_door_rect(self, door)
                if utils.rect_col(door_rect[1], door_rect[2], p1_rect[1], p1_rect[2]) then
                    return door
                end
            end

            return nil
        end

        return r
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
    end


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
        v.sprite = sprite
        v.target = target
        v.speed = speed
        v.state = "pursuit"
        v.stun_length = 0
        v.stun_elapsed = 0

        v.vel = v2.zero()
        v.dir_to_target = v2.zero()

        renderer.attach(v, sprite)
        v.renderable.draw_order = 10

        v.dislodge = function(self, p1, push_amount, stun_length)
            -- Push away from target back
            local push_vec = self.dir_to_target(self) * -1 * push_amount
            self.x += push_vec.x
            self.y += push_vec.y

            self.state = "stunned"
            self.stun_length = stun_length
        end

        v.dir_to_target = function(self)
            local d = self.target.v2_pos(self.target) - self.v2_pos(self)
            local dist = v2.mag(d)
            return v2.norm(d)
        end

        v.is_stunned = function(self)
            return self.state == "stunned"
        end

        v.update = function(self)
            if self.state == "pursuit" then
                self.vel =  self.dir_to_target(self) * self.speed
            elseif self.is_stunned(self) then
                self.stun_elapsed += 1
                self.vel = v2.zero()

                if self.stun_elapsed == self.stun_length then
                    self.stun_elapsed = 0
                    self.stun_length = 0
                    self.state = "pursuit"
                end
            end

            self.x += self.vel.x
            self.y += self.vel.y
        end

        v.get_rect = function(self)
            return { self.v2_pos(self), self.v2_pos(self) + v2.mk(8 - 1, 8 - 1) }
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
p1_walk_speed = 2
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
    local rows = 8
    local spritesheet_index = 64
    local x_offset = 64 - (cols * 8) / 2
    local y_offset = 64 - (rows * 8) / 2

    -- Generate the doors
    local num_doors = 2
    local doors = {}
    while #doors < num_doors do
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

        local new_door = v2.mk(x, y)
        local door_exists = false
        for d in all(doors) do
            if new_door.x == d.x and new_door.y == d.y then
                door_exists = true
                log.syslog("Duplicate coords at "..d.x..", "..d.y)
                break
            end
        end

        if not door_exists then
            add(doors, new_door)
        end
    end

    -- Generate some obstacles
    local num_obstacles = 1
    obstacles = {}
    for i=1,num_obstacles do
        local o = obstacle.mk(84, 64, 8, 8, 128)
        add(obstacles, o)
        add(scene, o)
    end

    level_room = room.mk(x_offset, y_offset, cols, rows, spritesheet_index, doors)
    add(scene, level_room)

    -- Add the player
    p1 = player.mk(64, 64, 1)
    add(scene, p1)

    -- Add the villain
    v1 = villain.mk(x_offset + doors[1].x * 8, y_offset + doors[1].y * 8, 32, p1, v1_speed)
    -- add(scene, v1)

    level_timer = secs_per_level * stat(8) -- secs * target FPS

    state = "ingame"
end

function restart_level()
    active_level_index -= 1
    next_level()
end

function reset_game()
    active_level_index = 0
    levels_completed = 0

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
        log.syslog("t1: "..bool_str(utils.pt_in_rect(v2.mk(44, 72), v2.mk(40, 68), v2.mk(48, 76))))
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

        -- @TODO Collide with obstacles
        for o in all(obstacles) do
            collide_with_obstacle(p1, o, 8, 8)
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

        if p1.stamina <= 0 then
            state = "gameover"
        elseif not is_p1_caught() and level_room.is_at_door(level_room, p1) then   -- Check if the player is at a door
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
        if actor_rect[2].x > obst_rect[1].x then
            actor.x = obst_rect[1].x - actor_size_x
        end

        if actor.vel.x < 0 and actor_rect[1].x < obst_rect[2].x then
            actor.x = obst_rect[2].x + 1
        end

        if actor.vel.y > 0 and actor_rect[2].y > obst_rect[1].y then
            actor.y = obst_rect[1].y - actor_size_y
        end

        if actor.vel.y < 0 and actor_rect[1].y < obst_rect[2].y then
            actor.y = obst_rect[2].y + 1
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
55555555bbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

