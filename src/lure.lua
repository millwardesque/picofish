game_obj = require('game_obj')
renderer = require('renderer')

local lure = {
    mk = function(name, x, y)
        local l = game_obj.mk(name, 'lure', x, y)
        renderer.attach(l, 2)

        return l
    end,
}

return lure
