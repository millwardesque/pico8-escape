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
