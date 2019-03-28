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
            if btnp(0) then
                p1_rod.cast_angle += 0.05
            end
            if btnp(1) then
                p1_rod.cast_angle -= 0.05
            end

            -- @TODO Control cast distance
            -- @TODO Show cast distance meter
            if btnp(4) then
                p1_rod.cast(p1_rod, 50)
            end
        elseif p1_rod.state == 'reeling' then
            if btn(4) then
                p1_rod.reel(p1_rod, 1)
            else
                p1_rod.reel(p1_rod, 0)
            end

            -- @TODO Auto-reel
            if btnp(5) then
                p1_rod.set_state(p1_rod, 'idle')
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
