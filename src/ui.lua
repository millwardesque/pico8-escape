local ui = {
    stamina = function(current, max)
        local margin = 4
        local w = 128 - (margin * 2)
        local h = 5
        local px_per_stamina = w / 100
        x0 = margin
        y = 127 - h - margin
        x1 = margin + (max * px_per_stamina)
        pct = (x1 - 1 - x0 - 1) * (current / max)

        rectfill(x0, y, x1, y + h, 14)
        rectfill(x0 + 1, y + 1, x0 + 1 + pct, y + h - 1, 8)
    end,

    horiz_wipe = function()
        local px_per_frame = 6
        for x=0, ceil(128 / px_per_frame) do
            rectfill(0, 0, x * px_per_frame, 127, 0)
            yield()
        end
    end
}
return ui
