game_cam = require('game_cam')
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
v1_spawn_delay = 2
v1_enabled = false

level_timer = nil
room_timer = nil
active_room = nil
next_room_to_load = nil
next_room_to_load_p1_start = nil
are_doors_active = false -- Doors become active once the player moves off the starting door
p1_start_cell = nil

rooms = nil
levels = {}
secs_per_level = 30
obstacles = {}

sky_colors = {0,1,2,13,14,9,6,12}
sky_step_length = flr(stat(8) * (secs_per_level + 1) / #sky_colors)
sky_frame_count = 0
sky_color_index = 0

background = {x = 0, y = 0, w = 16, h = 16}

scene = nil
state = "ingame"


function mk_rooms(num_rooms, min_dim, max_dim)
    local rooms = {}
    local room_pos = v2.mk(64, 64)
    for i = 1,num_rooms do
        local cols = min_dim + flr(rnd(max_dim - min_dim + 1))
        local rows = min_dim + flr(rnd(max_dim - min_dim + 1))
        local spritesheet_index = 64
        local rm = room.mk('rm-'..i, cols, rows, spritesheet_index, p1, max_dim)

        add(rooms, rm)
    end
    return rooms
end

function add_obstacles(rm, num_obstacles, sprite)
    local obstacles = {}
    for i=1,num_obstacles do
        -- Generate coords inside the room
        local x = rm.x + (1 + flr(rnd(rm.cols - 1))) * 8
        local y = rm.y + (1 + flr(rnd(rm.rows - 1))) * 8
        local o = obstacle.mk(x, y, 8, 8, sprite)

        add(obstacles, o)
    end
    rm.obstacles = obstacles
end

function connect_rooms(rooms)
    local doors = {}
    for i=1,#rooms do
        local next_room = i + 1
        if next_room > #rooms then
            next_room = 1
        end

        local d = door.mk(rooms[i], rooms[next_room])
        add(doors, d)

        room.add_door(d.exit1.rm, d)
        room.add_door(d.exit2.rm, d)
    end

    return doors
end

function generate_level()
    local num_rooms = 6
    local min_dim = 6
    local max_dim = 12
    rooms = mk_rooms(num_rooms, min_dim, max_dim)

    -- Generate some obstacles
    local num_obstacles = 2
    for rm in all(rooms) do
        local sprite = 128
        add_obstacles(rm, num_obstacles, sprite)
    end

    -- Connect rooms with doors
    connect_rooms(rooms)
end

function next_room()
    scene = {}

    cam = game_cam.mk("main-cam", 0, 0, 128, 128, 16, 16)
    add(scene, cam)

    -- Load the room
    active_room = next_room_to_load
    add(scene, active_room)
    add(scene, active_room.obstacles)
    are_doors_active = false

    -- Position player on the correct door
    p1_start_cell = next_room_to_load_p1_start
    local p1_pos = room.world_pos(active_room, p1_start_cell)
    p1.x = p1_pos.x
    p1.y = p1_pos.y
    add(scene, p1)

    -- Add the villain
    local v1_die_roll = flr(rnd(3))
    local v1_start_cell = nil
    if v1_die_roll == 0 and #active_room.doors >= 1 then
        v1_start_cell = active_room.doors[1].get_coords(active_room.doors[1], active_room)
    elseif v1_die_roll == 1 and #active_room.doors >= 2 then
        v1_start_cell = active_room.doors[2].get_coords(active_room.doors[2], active_room)
    else
        v1_start_cell = utils.rnd_outer_grid(active_room.rows, active_room.cols)
    end
    local v1_start = room.world_pos(active_room, v1_start_cell)
    v1 = villain.mk(v1_start.x, v1_start.y, 32, p1, v1_speed)
    -- Note: This has been moved into update to allow for a spawn delay: add(scene, v1)

    v1.set_path(v1, room.find_path(active_room, v1.get_centre(v1), p1.get_centre(p1)))

    if level_timer == nil then
        level_timer = secs_per_level * stat(8)
    end

    room_timer = 0

    state = "ingame"
end

function restart_room()
    next_room()
end

function reset_game()
    if p1 == nil then
        p1 = player.mk(0, 0, 0)
    end

    v1 = nil
    level_timer = nil
    sky_color_index = 0
    sky_frame_count = 0

    generate_level()

    next_room_to_load = rooms[1]
    next_room_to_load_p1_start = rooms[1].doors[1].get_coords(rooms[1].doors[1], rooms[1])
    next_room()
end

function _init()
    log.debug = true

    reset_game()
end

function is_p1_caught()
    return p1_caught_time > 0
end

function _update()
    if state == "ingame" then
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
            restart_room()
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
        room_timer += 1

        if room_timer == v1_spawn_delay * stat(8) then
            add(scene, v1)
            v1_enabled = true
        end

        if level_timer == 0 then
            state = "gameover"
        end

        for obj in all(scene) do
            if obj.update then
                obj.update(obj)
            end
        end

        -- Adjust actors to be in room
        restrict_to_room(active_room, p1, 8, 8)

        if v1_enabled then
            restrict_to_room(active_room, v1, 8, 8)
        end

        -- Collide with obstacles
        for o in all(active_room.obstacles) do
            collide_with_obstacle(p1, o, 8, 8)

            if v1_enabled then
                collide_with_obstacle(v1, o, 8, 8)
            end
        end

        -- Check if the player has moved off the starting square
        local p1_rect = p1.get_rect(p1)
        local start_cell_rect = room.cell_rect(active_room, p1_start_cell)
        if false == are_doors_active and false == utils.rect_col(p1_rect[1], p1_rect[2], start_cell_rect[1], start_cell_rect[2]) then
            are_doors_active = true
        end

        p1_rect = p1.get_rect(p1)
        v1_rect = v1.get_rect(v1)
        if v1_enabled and not v1.is_stunned(v1) and utils.rect_col(p1_rect[1], p1_rect[2], v1_rect[1], v1_rect[2]) then
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

        -- Update villain pathing
        -- @TODO This is out of place, but easiest for now
        if v1_enabled and level_timer % flr(stat(8) / 4) == 0 then
            v1.set_path(v1, room.find_path(active_room, v1.get_centre(v1), p1.get_centre(p1)))
        end

        sky_frame_count += 1
        while sky_frame_count >= sky_step_length do
            sky_frame_count -= sky_step_length
            sky_color_index = (sky_color_index + 1) % #sky_colors
        end

        if p1.stamina <= 0 then
            state = "gameover"
        elseif are_doors_active and not is_p1_caught() then   -- Check if the player is at a door
            local d = active_room.is_at_door(active_room, p1)
            if d != nil then
                local exit = d.other_exit(d, active_room)
                next_room_to_load = exit.rm
                next_room_to_load_p1_start = exit.coords

                state = "complete"
                screen_wipe = cocreate(ui.horiz_wipe)
            end
        end
    elseif state == "complete" then
        if costatus(screen_wipe) == 'dead' then
            next_room()
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
        local last_rect = actor.get_last_rect(actor)
        local is_lhs = last_rect[2].x < obst_rect[1].x
        local is_rhs = last_rect[1].x > obst_rect[2].x
        local is_top = last_rect[2].y < obst_rect[1].y
        local is_bottom = last_rect[1].y > obst_rect[2].y

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
        log.log("press 4 to try again")
    end
    log.render()
end
