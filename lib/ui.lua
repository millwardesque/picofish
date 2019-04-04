local ui = {
    render_power_bar = function(current, max)
        w = 120
        h = 10
        x0 = (128 - w) / 2
        y = 4
        x1 = 127 - ((128 - w) / 2)
        pct = (x1 - 1 - x0 - 1) * (current / max)
        current_x0 = x0 + 1
        current_x1 = x0 + 1 + pct

        rectfill(x0, y, x1, y + h, 14)
        rectfill(current_x0, y + 1, current_x1, y + h - 1, 8)
    end
}
return ui
