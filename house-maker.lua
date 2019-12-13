game_cam = require('game_cam')
log = require('log')
renderer = require('renderer')
utils = require('utils')

door = require('door')
obstacle = require('obstacle')
player = require('player')
room = require('room')

scene = {}
background = {x = 0, y = 0, w = 16, h = 16}
p1 = nil
p1_walk_speed = 3
rooms = nil
are_doors_active = false


function _init()
    restart_level()
end

function mk_rooms(num_rooms, min_dim, max_dim)
    local rooms = {}
    local room_pos = v2.mk(64, 64)
    for i = 1,num_rooms do
        local cols = min_dim + flr(rnd(max_dim - min_dim + 1))
        local rows = min_dim + flr(rnd(max_dim - min_dim + 1))
        local spritesheet_index = 64

        -- Space the rooms out visually. Only needed in house-maker
        local rm = room.mk('rm-'..i, cols, rows, spritesheet_index, p1, max_dim)
        rm.x = room_pos.x
        rm.y = room_pos.y
        room_pos.x += (cols + 1) * 8

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

function restart_level()
    scene = {}

    cam = game_cam.mk("main-cam", 0, 0, 128, 128, 16, 16)
    add(scene, cam)

    p1 = player.mk(64, 64, 0)
    add(scene, p1)
    cam.cam.target = p1

    -- Generate the rooms
    local num_rooms = 6
    local min_dim = 6
    local max_dim = 12
    rooms = mk_rooms(num_rooms, min_dim, max_dim)

    for r in all(rooms) do
        add(scene, r)
    end

    -- Generate some obstacles
    local num_obstacles = 2
    for rm in all(rooms) do
        add_obstacles(rm, num_obstacles, 128)

        for o in all(rm.obstacles) do
            add(scene, o)
        end
    end

    -- Generate some doors
    connect_rooms(rooms)

    are_doors_active = false
end

function _update()
    p1.vel = v2.zero()
    local p1_speed = p1_walk_speed

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

    for obj in all(scene) do
        if obj.update then
            obj.update(obj)
        end
    end

    if are_doors_active then
        for rm in all(rooms) do
            local d = rm.is_at_door(rm, p1)
            if d != nil then
                local exit = d.other_exit(d, rm)
                local next_room = exit.rm
                local p1_pos = next_room.get_door_rect(next_room, d)[1]
                p1.x = p1_pos.x
                p1.y = p1_pos.y

                are_doors_active = false
                break
            end
        end
    else  -- Check if the player has moved off the starting square
        local p1_rect = p1.get_rect(p1)
        local is_p1_on_door = false
        for rm in all(rooms) do
            for d in all(rm.doors) do
                local door_rect = rm.get_door_rect(rm, d)
                if utils.rect_col(p1_rect[1], p1_rect[2], door_rect[1], door_rect[2]) then
                    is_p1_on_door = true
                    break
                end
            end

            if is_p1_on_door then
                break
            end
        end

        if false == is_p1_on_door then
            are_doors_active = true
        end
    end
end

function _draw()
    cls(0)

    -- Draw the game
    renderer.render(cam, scene, background)

    log.render()
end