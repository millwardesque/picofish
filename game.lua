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
current_power = 0
max_power = 100

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
                p1_rod.cast_angle = mid(0.55, p1_rod.cast_angle, 0.95)

                if btn(4) then
                    current_power = mid(0, current_power + 1, 100)

                else
                    if current_power > 0 then
                        p1_rod.cast(p1_rod, current_power)
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
    ui.render_power_bar(current_power, max_power)

    log.render()
end
