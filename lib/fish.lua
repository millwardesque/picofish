game_obj = require('game_obj')
log = require('log')
v2 = require('v2')

local fish = {
    mk = function(name, x, y)
        local f = game_obj.mk(name, 'fish', x, y)
        f.visible = true
        f.state = 'swim'
        f.target = nil
        f.speed = 0.15

        renderer.attach(f, 1)

        f.update = function(self)
            -- Show / hide randomly
            if self.visible == true and flr(rnd(500)) == 1 then
                self.hide(self)
            elseif self.visible == false and flr(rnd(500)) then
                self.show(self)
            end

            if self.state == 'swim' then
                if self.target == nil then
                    self.target = v2.mk(rnd(128), rnd(128))
                end

                local dist = self.target - self.v2_pos(self)
                if v2.mag(dist) < 4 then   -- Target reached
                    self.target = nil
                else                    -- Swim to target
                    local vel = v2.norm(dist) * self.speed
                    self.x += vel.x
                    self.y += vel.y
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
