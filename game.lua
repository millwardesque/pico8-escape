game_cam = require('game_cam')
game_obj = require('game_obj')
log = require('log')
renderer = require('renderer')
v2 = require('v2')

level = require('level')
player = require('player')
room = require('room')
utils = require('utils')
villain = require('villain')
ui = require('ui')

cam = nil
p1 = nil
p1_speed = 2
p1_caught_time = 0

injury_time = 20
injury_amount = 5

v1 = nil
v1_speed = 1.5

level_timer = nil
level_room = nil

active_level = nil
active_level_index = nil
levels = {}
levels_completed = 0
secs_per_level = 30

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
    for i=1, num_doors do

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

        add(doors, v2.mk(x, y))
    end

    level_room = room.mk(x_offset, y_offset, cols, rows, spritesheet_index, doors)
    add(scene, level_room)

    -- Add the player
    p1 = player.mk(64, 64, 1)
    add(scene, p1)

    -- Add the villain
    v1 = villain.mk(x_offset + doors[1].x * 8, y_offset + doors[1].y * 8, 32, p1, v1_speed)
    add(scene, v1)

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

function _update()
    if state == "test" then
        log.syslog("t1: "..bool_str(utils.pt_in_rect(v2.mk(44, 72), v2.mk(40, 68), v2.mk(48, 76))))
    elseif state == "ingame" then
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

        p1_rect = p1.get_rect(p1)
        v1_rect = v1.get_rect(v1)
        if utils.rect_col(p1_rect[1], p1_rect[2], v1_rect[1], v1_rect[2]) then
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
        elseif level_room.is_at_door(level_room, p1) then   -- Check if the player is at a door
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
