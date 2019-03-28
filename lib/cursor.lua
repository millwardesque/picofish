game_obj = require('game_obj')
renderer = require('renderer')

local cursor = {
    mk = function(name, x, y)
        local c = game_obj.mk(name, 'cursor', x, y)
        renderer.attach(c, 4)

        return c
    end,
}

return cursor
