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
