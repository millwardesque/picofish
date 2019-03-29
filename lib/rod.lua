cursor = require('cursor')
game_obj = require('game_obj')
log = require('log')
lure = require('lure')
renderer = require('renderer')
v2 = require('v2')

function calculate_cast_dir(angle)
    return v2.mk(cos(angle), sin(angle))
end

function lure_home(r)
    return v2.mk(r.x, r.y - 10)
end

local rod = {
    mk = function(name, x, y)
        local r = game_obj.mk(name, 'rod', x, y)
        local lure_pos = lure_home(r)

        r.lure = lure.mk('lure', lure_pos.x, lure_pos.y)
        r.cursor = cursor.mk('cursor', lure_pos.x, lure_pos.y)
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

        r.dist_to_reel = function(self)
            return v2.mag(lure_home(self) - self.lure.v2_pos(self.lure))
        end

        r.dir_to_reel = function(self)
            return self.dir_to_reel_offset(self, v2.zero())
        end

        r.dir_to_reel_offset = function(self, offset)
            return v2.norm((lure_home(self) + v2.mk(offset.x, offset.y)) - self.lure.v2_pos(self.lure))
        end

        r.cast = function(self, distance)
            self.cast_distance = distance
            self.set_state(self, 'casting')
        end

        r.reel = function(self, distance)
            self.vel = distance * self.dir_to_reel(self)
        end

        r.drag = function(self, distance, x_offset)
            self.vel = distance * self.dir_to_reel_offset(self, v2.mk(x_offset, abs(x_offset) * 2.0 / 3.0))
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

                local distance = self.dist_to_reel(self)
                if distance >= self.cast_distance then
                    self.set_state(self, 'reeling')
                end
            elseif self.state == 'reeling' then
                self.lure.x += self.vel.x
                self.lure.y += self.vel.y

                --if v2.mag(v2.mk(self.lure.x, self.lure.y) - v2.mk(self.x, self.y - 10)) > self.cast_distance then
                --    local new_lure = self.cast_distance * v2.norm(v2.mk(self.lure.x, self.lure.y) - v2.mk(self.x, self.y))
                --    self.lure.x = self.x + new_lure.x
                --    self.lure.y = self.y - 10 - new_lure.y
                --end

                if self.lure.y > lure_home(self).y then
                    self.lure.y = lure_home(self).y
                end

                local distance = self.dist_to_reel(self)
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
                self.lure.x = lure_home(self).x
                self.lure.y = lure_home(self).y
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
