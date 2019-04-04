game_obj = require('game_obj')
log = require('log')

local fish = {
    mk = function(name, x, y)
        local f = game_obj.mk(name, 'fish', x, y)
        f.visible = true

        renderer.attach(f, 1)

        f.update = function(self)
            -- Show / hide randomly
            if (flr(rnd(100)) == 1) then
                if self.visible == true then
                    self.hide(self)
                else
                    self.show(self)
                end
            end
        end

        f.show = function(self)
            f.renderable.enabled = true
            self.visible = true
        end

        f.hide = function(self)
            f.renderable.enabled = false
            self.visible = false
        end

        return f
    end,
}

return fish
