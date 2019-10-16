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
