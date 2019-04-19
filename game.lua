game_cam = require('game_cam')
game_obj = require('game_obj')
log = require('log')
renderer = require('renderer')
v2 = require('v2')

fish = require('fish')
rod = require('rod')
ui = require('ui')

map = 1
water = {13, 12, 1}

cam = nil
fishes = nil
scene = nil
state = "ingame"
p1_rod = nil
power_direction_mult = 1
current_power = 0
cast_power_incr = 2
max_power = 100
add_freq = 100
remove_freq = 1000
max_fish = 5
min_cast_dist = 5
min_cast_angle = 0.55
max_cast_angle = 0.95

function add_fish()
    local x = flr(rnd(100))
    local y = flr(rnd(100))
    local new_fish = fish.mk('f'..#fishes, x, y)
    add(fishes, new_fish)
    add(scene, new_fish)
end

function remove_fish()
    if #fishes > 0 then
        local i = flr(rnd(#fishes)) + 1
        local f = fishes[i]
        del(scene, f)
        del(fishes, f)
    end
end

function _init()
    log.debug = true
    state = "ingame"
    scene = {}

    cam = game_cam.mk("main-cam", 0, 0, 128, 128, 16, 16)
    add(scene, cam)

    fishes = {}
    add_fish()

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

        if p1_rod.state == 'idle' then
            if (not p1_rod.can_cast) then
                if not btn(4) then
                    p1_rod.can_cast = true
                    current_power = 0
                end
            else
                if btnp(0) then
                    p1_rod.cast_angle += 0.05
                end
                if btnp(1) then
                    p1_rod.cast_angle -= 0.05
                end
                p1_rod.cast_angle = mid(min_cast_angle, p1_rod.cast_angle, max_cast_angle)

                if btn(4) then
                    current_power = mid(0, current_power + cast_power_incr, max_power)

                    if current_power == 0 or current_power == max_power then
                        cast_power_incr *= -1
                    end
                else
                    if current_power > min_cast_dist then
                        p1_rod.cast(p1_rod, current_power)
                    else
                        current_power = 0
                    end
                end
            end
        elseif p1_rod.state == 'reeling' then
            if not p1_rod.can_reel then
                if not btn(4) then
                    p1_rod.can_reel = true
                end
            else
                if not p1_rod.auto_reeling then
                    if btnp(5) then
                        p1_rod.auto_reel(p1_rod, 1)
                    elseif btn(4) then
                        if btn(0) then
                            p1_rod.drag(p1_rod, 1, -10)
                        elseif btn(1) then
                            p1_rod.drag(p1_rod, 1, 10)
                        else
                            p1_rod.reel(p1_rod, 1)
                        end
                    else
                        p1_rod.reel(p1_rod, 0)
                    end
                end
            end
        end

        -- Add / remove fish
        if (#fishes < max_fish and flr(rnd(add_freq)) == 1) then
          add_fish()
        end
        if (#fishes > 0 and flr(rnd(remove_freq)) == 1) then
            remove_fish()
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
    --log.log("Mem: "..(stat(0)/2048.0).."% CPU: "..(stat(1)/1.0).."%")
    log.log("fish: "..#fishes.." rod: "..p1_rod.state)
end

function _draw()
    cls(water[map])

    background = nil
    renderer.render(cam, scene, background)
    ui.render_power_bar(current_power, max_power)

    log.render()
end
