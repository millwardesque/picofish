game_obj = require('game_obj')
log = require('log')
lure = require('lure')
renderer = require('renderer')

local rod = {
    mk = function(name, x, y)
        local r = game_obj.mk(name, 'rod', x, y)
        r.lure = lure.mk('lure', x, y - 10)
        r.state = 'idle'

        renderer.attach(r, 3)

        r.renderable.render = function(self, x, y)
            r.renderable.default_render(self, x, y)

            if self.game_obj.state == 'cast' then
                line(x + 4, y - 1, self.game_obj.lure.x + 4, self.game_obj.lure.y + 8, 7)
            end
        end

        r.set_state = function(self, state)
            -- @TODO Casting
            -- @TODO Reeling
            -- @TODO Animate

            if state == 'idle' and self.state ~= state then
                self.lure.x = self.x
                self.lure.y = self.y - 10
            elseif state == 'cast' and self.state ~= state then
                x_range = 56
                x_offset = flr(rnd(x_range * 2)) - x_range

                y_range = 100
                y_offset = flr(rnd(y_range))

                self.lure.x = self.x + x_offset
                self.lure.y = self.y - 10 - y_offset
            end

            self.state = state
        end

        return r
    end,
}

return rod
