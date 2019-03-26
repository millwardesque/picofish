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
end

function _update()
    if state == "ingame" then
        for obj in all(scene) do
            if obj.update then
                obj.update(obj)
            end
        end

        if btnp(4) then
            p1_rod.set_state(p1_rod, 'cast')
        end
        if btnp(5) then
            p1_rod.set_state(p1_rod, 'idle')
        end

        -- Map toggle
        if btnp(2) then
            map -= 1
        end
        if btnp(3) then
            map += 1
        end
        map = mid(1, map, #water)
    end

    -- Debug
    -- log.log("Mem: "..stat(0).." CPU: "..stat(1))
end

function _draw()
    cls(water[map])

    background = nil
    renderer.render(cam, scene, background)

    log.render()
end
