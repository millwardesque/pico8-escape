game_cam = require('game_cam')
game_obj = require('game_obj')
log = require('log')
renderer = require('renderer')
v2 = require('v2')

obstacle = require('obstacle')
player = require('player')
room = require('room')

p1 = nil
p1_speed = 1
scene = {}
p1_path = nil
t1 = nil

function restrict_to_room(room, actor)
    local room_rect = room.get_room_rect(room)
    local actor_rect = actor.get_rect(actor)

    if actor_rect[1].x < room_rect[1].x then
        actor.x = room_rect[1].x
    end

    if actor_rect[2].x >= room_rect[2].x then
        actor.x = room_rect[2].x - actor.w
    end

    if actor_rect[1].y < room_rect[1].y then
        actor.y = room_rect[1].y
    end

    if actor_rect[2].y >= room_rect[2].y then
        actor.y = room_rect[2].y - actor.h
    end
end

function collide_with_obstacle(actor, obst)
    local obst_rect = obst.get_rect(obst)
    local actor_rect = actor.get_rect(actor)

    if utils.rect_col(actor_rect[1], actor_rect[2], obst_rect[1], obst_rect[2]) then
        local actor_last_rect = actor.get_last_rect(actor)
        local is_lhs = actor_last_rect[2].x < obst_rect[1].x
        local is_rhs = actor_last_rect[1].x > obst_rect[2].x
        local is_top = actor_last_rect[2].y < obst_rect[1].y
        local is_bottom = actor_last_rect[1].y > obst_rect[2].y

        if is_lhs and not is_rhs and not is_top and not is_bottom then
            actor.x = obst_rect[1].x - actor.w
        elseif is_rhs and not is_lhs and not is_top and not is_bottom then
            actor.x = obst_rect[2].x + 1
        elseif is_bottom and not is_top and not is_lhs and not is_rhs then
            actor.y = obst_rect[2].y + 1
        elseif is_top and not is_bottom and not is_lhs and not is_rhs then
            actor.y = obst_rect[1].y - actor.h
        end
    end
end


function _init()
    restart_level()
end

function restart_level()
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
    local num_obstacles = 2
    obstacles = {}
    for i=1,num_obstacles do

        -- Generate coords inside the room
        local x = x_offset + (1 + flr(rnd(cols - 1))) * 8
        local y = y_offset + (1 + flr(rnd(rows - 1))) * 8

        local o = obstacle.mk(x, y, 8, 8, 128)
        add(obstacles, o)
        add(scene, o)
    end
    rm = room.mk(x_offset, y_offset, cols, rows, spritesheet_index)
    rm.obstacles = obstacles

    -- Generate the doors
    local num_doors = 2
    room.generate_doors(rm, num_doors)
    add(scene, rm)

    -- Generate the t1
    t1 = game_obj.mk('t1', 't1', 96, 84)

    -- Generate the player
    p1 = player.mk(48, 48, 1)
    add(scene, p1)
    p1_path = room.find_path(rm, p1.v2_pos(p1), t1.v2_pos(t1))
end

function _update()
    p1.vel = v2.zero()

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

    -- Adjust actors to be in room
    restrict_to_room(rm, p1)

    -- Collide with obstacles
    for o in all(obstacles) do
        collide_with_obstacle(p1, o)
    end

    p1_path = room.find_path(rm, p1.v2_pos(p1), t1.v2_pos(t1))
end

function _draw()
    cls(0)

    -- Draw the player / room
    renderer.render(cam, scene, background)

    -- @TODO Draw the path
    for p in all(p1_path) do
        rectfill(p.x, p.y, p.x + 7, p.y + 7, 2)
    end

    -- Draw the t1
    color(8)
    circ(t1.x, t1.y, 1)

    log.render()
end