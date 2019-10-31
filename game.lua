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
