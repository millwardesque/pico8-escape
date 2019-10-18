local ui = {
    render_stamina = function(current, max)
        container_margin = 4
        container_width = 128 - (container_margin * 2)
        px_per_stamina = container_width / 100
        h = 5
        x0 = container_margin
        y = 127 - h - container_margin
        x1 = container_margin + (max * px_per_stamina)
        pct = (x1 - 1 - x0 - 1) * (current / max)
        current_x0 = x0 + 1
        current_x1 = x0 + 1 + pct

        rectfill(x0, y, x1, y + h, 14)
        rectfill(current_x0, y + 1, current_x1, y + h - 1, 8)
    end
}
return ui
