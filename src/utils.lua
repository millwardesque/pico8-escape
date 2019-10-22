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
    end
}

return utils
