local game_obj = {
    mk = function(name, type, pos_x, pos_y)
        local g = {
            name = name,
            type = type,
            x = pos_x,
            y = pos_y,
        }
        g.update = function(self)
        end

        return g
    end
}
return game_obj
