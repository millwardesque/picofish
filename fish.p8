pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
package={loaded={},_c={}}
package._c["game_cam"]=function()
game_obj = require('game_obj')

local game_cam = {
    mk = function(name, pos_x, pos_y, width, height, bounds_x, bounds_y)
        local c = game_obj.mk(name, 'camera', pos_x, pos_y)
        c.cam = {
            w = width,
            h = height,
            bounds_x = bounds_x,
            bounds_y = bounds_y,
            target = nil,
        }

        c.update = function(cam)
            -- Track a target
            target = cam.cam.target
            if target ~= nil then
                if target.x < cam.x + cam.cam.bounds_x then
                    cam.x = target.x - cam.cam.bounds_x
                elseif target.x > cam.x + cam.cam.w - cam.cam.bounds_x then
                    cam.x = target.x - cam.cam.w + cam.cam.bounds_x
                end

                if target.y < cam.y + cam.cam.bounds_y then
                    cam.y = target.y - cam.cam.bounds_y
                elseif target.y > cam.y + cam.cam.h - cam.cam.bounds_y then
                    cam.y = target.y - cam.cam.h + cam.cam.bounds_y
                end
            end

            -- Prevent camera from scrolling off the top-left side of the map
            if cam.x < 0 then cam.x = 0 end
            if cam.y < 0 then cam.y = 0 end
        end

        return c
    end,
    draw_start = function (cam)
        camera(cam.x, cam.y)
        clip(0, 0, cam.cam.w, cam.cam.h)
    end,
    draw_end = function(cam)
        camera()
        clip()
    end,
}
return game_cam
end
package._c["game_obj"]=function()
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
end
package._c["log"]=function()
local log = {
    debug = true,
    file = 'debug.log',
    _data = {},

    log = function(msg)
        add(log._data, msg)
    end,
    syslog = function(msg)
        printh(msg, log.file)
    end,
    render = function()
        if log.debug then
            color(7)
            for i = 1, #log._data do
                print(log._data[i], 5, 8 * i)
            end
        end

        log._data = {}
    end,
}
return log
end
package._c["renderer"]=function()
log = require('log')

local renderer = {
    render = function(cam, scene, bg)
        -- Collect renderables
        local to_render = {};
        for obj in all(scene) do
            if (obj.renderable) then
                if obj.renderable.enabled then
                    add(to_render, obj)
                end
            end
        end

        -- Sort
        renderer.sort(to_render)

        -- Draw
        game_cam.draw_start(cam)

        if bg then
            map(bg.x, bg.y, 0, 0, bg.w, bg.h)
        end

        for obj in all(to_render) do
            obj.renderable.render(obj.renderable, obj.x, obj.y)
        end

        game_cam.draw_end(cam)
    end,

    attach = function(game_obj, sprite)
        local r = {
            game_obj = game_obj,
            sprite = sprite,
            flip_x = false,
            flip_y = false,
            w = 1,
            h = 1,
            draw_order = 0,
            palette = nil,
            enabled = true
        }

        -- Default rendering function
        r.render = function(self, x, y)
            -- Set the palette
            if (self.palette) then
                -- Set colours
                for i = 0, 15 do
                    pal(i, self.palette[i + 1])
                end

                -- Set transparencies
                for i = 17, #self.palette do
                    palt(self.palette[i], true)
                end
            end

            -- Draw
            spr(self.sprite, x, y, self.w, self.h, self.flip_x, self.flip_y)

            -- Reset the palette
            if (self.palette) then
                pal()
                palt()
            end
        end

        -- Save the default render function in case the obj wants to use it in an overridden render function.
        r.default_render = r.render

        game_obj.renderable = r;
        return game_obj;
    end,

    -- Sort a renderable array by draw-order
    sort = function(list)
        renderer.sort_helper(list, 1, #list)
    end,
    -- Helper function for sorting renderables by draw-order
    sort_helper = function (list, low, high)
        if (low < high) then
            local p = renderer.sort_split(list, low, high)
            renderer.sort_helper(list, low, p - 1)
            renderer.sort_helper(list, p + 1, high)
        end
    end,
    -- Partition a renderable list by draw_order
    sort_split = function (list, low, high)
        local pivot = list[high]
        local i = low - 1
        local temp
        for j = low, high - 1 do
            if (list[j].renderable.draw_order < pivot.renderable.draw_order or
                (list[j].renderable.draw_order == pivot.renderable.draw_order and list[j].y < pivot.y)) then
                i += 1
                temp = list[j]
                list[j] = list[i]
                list[i] = temp
            end
        end

        if (list[high].renderable.draw_order < list[i + 1].renderable.draw_order or
            (list[high].renderable.draw_order == list[i + 1].renderable.draw_order and list[high].y < list[i + 1].y)) then
            temp = list[high]
            list[high] = list[i + 1]
            list[i + 1] = temp
        end

        return i + 1
    end
}
return renderer
end
package._c["v2"]=function()
local v2 = {
    mk = function(x, y)
        local v = {x = x, y = y,}
        setmetatable(v, v2.meta)
        return v;
    end,
    clone = function(x, y)
        return v2.mk(v.x, v.y)
    end,
    zero = function()
        return v2.mk(0, 0)
    end,
    mag = function(v)
        if v.x == 0 and v.y == 0 then
            return 0
        else
            return sqrt(v.x ^ 2 + v.y ^ 2)
        end
    end,
    norm = function(v)
        local m = v2.mag(v)
        if m == 0 then
            return v
        else
            return v2.mk(v.x / m, v.y / m)
        end
    end,
    str = function(v)
        return "("..v.x..", "..v.y..")"
    end,
    meta = {
        __add = function (a, b)
            return v2.mk(a.x + b.x, a.y + b.y)
        end,

        __sub = function (a, b)
            return v2.mk(a.x - b.x, a.y - b.y)
        end,

        __mul = function (a, b)
            if type(a) == "number" then
                return v2.mk(a * b.x, a * b.y)
            elseif type(b) == "number" then
                return v2.mk(b * a.x, b * a.y)
            else
                return v2.mk(a.x * b.x, a.y * b.y)
            end
        end,

        __div = function(a, b)
            v2.mk(a.x / b, a.y / b)
        end,

        __eq = function (a, b)
            return a.x == b.x and a.y == b.y
        end,
    },
}
return v2
end
package._c["fish"]=function()
game_obj = require('game_obj')
log = require('log')

local fish = {
    mk = function(name, x, y)
        local f = game_obj.mk(name, 'fish', x, y)
        f.visible = true

        renderer.attach(f, 1)

        f.update = function(self)
            -- @TODO Move
            -- @TODO Bite

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
end
package._c["rod"]=function()
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
end
package._c["cursor"]=function()
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
end
package._c["lure"]=function()
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
end
function require(p)
local l=package.loaded
if (l[p]==nil) l[p]=package._c[p]()
if (l[p]==nil) l[p]=true
return l[p]
end
game_cam = require('game_cam')
game_obj = require('game_obj')
log = require('log')
renderer = require('renderer')
v2 = require('v2')

fish = require('fish')
rod = require('rod')

map = 1
water = {13, 12, 1}

cam = nil
fishes = nil
scene = nil
state = "ingame"
p1_rod = nil

function _init()
    log.debug = true
    state = "ingame"
    scene = {}

    cam = game_cam.mk("main-cam", 0, 0, 128, 128, 16, 16)
    add(scene, cam)

    fishes = {}
    add(fishes, fish.mk('f1', 10, 20))
    add(fishes, fish.mk('f2', 60, 92))
    add(scene, fishes[1])
    add(scene, fishes[2])

    p1_rod = rod.mk('rod', 64, 110)
    add(scene, p1_rod)
    add(scene, p1_rod.lure)
    add(scene, p1_rod.cursor)
end

function _update()
    if state == "ingame" then
        for obj in all(scene) do
            if obj.update then
                obj.update(obj)
            end
        end

        -- @TODO Show cast direction cursor
        -- @TODO Don't cast if we just got out of reeling state and user hasn't let go of button
        if p1_rod.state == 'idle' then
            if (not p1_rod.can_cast) then
                if not btn(4) then
                    p1_rod.can_cast = true
                end
            else
                if btnp(0) then
                    p1_rod.cast_angle += 0.05
                end
                if btnp(1) then
                    p1_rod.cast_angle -= 0.05
                end
                p1_rod.cast_angle = mid(0.55, p1_rod.cast_angle, 0.95)

                -- @TODO Control cast distance
                -- @TODO Show cast distance meter
                if btnp(4) then
                    p1_rod.cast(p1_rod, 50)
                end
            end
        elseif p1_rod.state == 'reeling' then
            if not p1_rod.can_reel then
                if not btn(4) then
                    p1_rod.can_reel = true
                end
            else
                if btnp(5) then
                    p1_rod.auto_reel(p1_rod, 1)
                elseif btn(4) then
                    p1_rod.reel(p1_rod, 1)
                elseif not p1_rod.auto_reeling then
                    p1_rod.reel(p1_rod, 0)
                end
            end
        end

        -- Debug Map toggle
        if btnp(2) then
            map -= 1
        end
        if btnp(3) then
            map += 1
        end
        map = mid(1, map, #water)
    end

    -- Debug
    log.log("Mem: "..stat(0).." CPU: "..stat(1))
    log.log(p1_rod.state)
end

function _draw()
    cls(water[map])

    background = nil
    renderer.render(cam, scene, background)

    log.render()
end
__gfx__
00000000022002200099990000040000eee77eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000220000000900000040000ee7ee7ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000030002222000000900000040000e7eeee7e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000003000222222000009000000400007ee77ee70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030030000222222000009000000400007ee77ee70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00330000022222200000900000040000e7eeee7e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000002222000900900000555500ee7ee7ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000000220000099000000044000eee77eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

