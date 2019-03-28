cursor = require('cursor')
game_obj = require('game_obj')
log = require('log')
lure = require('lure')
renderer = require('renderer')
v2 = require('v2')

function calculate_cast_dir(angle)
    return v2.mk(cos(angle), sin(angle))
end

local rod = {
    mk = function(name, x, y)
        local r = game_obj.mk(name, 'rod', x, y)
        r.lure = lure.mk('lure', x, y - 10)
        r.cursor = cursor.mk('cursor', x, y - 10)
        r.cast_speed = 1.5

        r.state = nil
        r.vel = nil
        r.cast_distance = nil
        r.cast_angle = nil
        r.can_cast = false
        r.can_reel = false
        r.auto_reeling = false

        renderer.attach(r, 3)

        r.renderable.render = function(self, x, y)
            self.default_render(self, x, y)

            if self.game_obj.state == 'casting' or self.game_obj.state == 'reeling' then
                line(x + 4, y - 1, self.game_obj.lure.x + 4, self.game_obj.lure.y + 8, 7)
            end
        end

        r.cast = function(self, distance)
            if self.state == 'idle' then
                self.cast_distance = distance
                self.set_state(self, 'casting')
            end
        end

        r.reel = function(self, distance)
            if self.state == 'reeling' then
                self.vel = distance * calculate_cast_dir(self.cast_angle)
            end
        end

        r.auto_reel = function(self, distance)
            if self.state == 'reeling' then
                self.auto_reeling = true
                self.reel(self, distance)
            end
        end

        r.update = function(self)
            if self.state == 'idle' then
                local pos = calculate_cast_dir(self.cast_angle) * 10
                self.cursor.x = self.x - pos.x
                self.cursor.y = self.y - pos.y
            elseif self.state == 'casting' then
                self.lure.x += self.vel.x
                self.lure.y += self.vel.y

                local distance = v2.mag(v2.mk(self.lure.x, self.lure.y) - v2.mk(self.x, self.y))
                if distance >= self.cast_distance then
                    self.set_state(self, 'reeling')
                end
            elseif self.state == 'reeling' then
                self.lure.x += self.vel.x
                self.lure.y += self.vel.y

                local distance = v2.mag(v2.mk(self.lure.x, self.lure.y) - v2.mk(self.x, self.y))
                if distance <= 12 then
                    self.set_state(self, 'idle')
                end
            end
        end

        r.is_in_water = function(self)
            return self.state == 'reeling' and not self.auto_reeling
        end

        r.set_state = function(self, state)
            if state == 'idle' and self.state ~= state then
                self.lure.x = self.x
                self.lure.y = self.y - 10
                self.lure.renderable.enabled = false
                self.cursor.renderable.enabled = true
                self.vel = v2.zero()
                self.cast_distance = 0
                self.cast_angle = 0.75
                self.auto_reeling = false
                self.state = state
            elseif state == 'casting' and self.state == 'idle' and self.can_cast == true then
                local dir = -self.cast_speed * calculate_cast_dir(self.cast_angle)
                self.vel = dir
                self.lure.renderable.enabled = true
                self.cursor.renderable.enabled = false
                self.state = state
                self.can_cast = false
                self.can_reel = false
            elseif state == 'reeling' and self.state == 'casting' then
                self.vel = v2.zero()
                self.cast_distance = 0
                self.state = state
            else
                return false
            end

            return true
        end

        r.set_state(r, 'idle')
        return r
    end,
}

return rod
