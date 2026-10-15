local component = require("constants.component")
local harness = require("tests.harness")
local mutations = require("ids.mutations")
local noise = require("policy.world.noise")
local records = require("policy.mutations.records")
local terrain = require("constants.terrain")

local test = {}

local function corridor(ctx, player, door, visible)
    local world = setmetatable({}, { __index = ctx })

    function world.player()
        return player
    end

    function world.visible()
        return visible ~= false
    end

    function world.aut()
        return 0
    end

    function world.random(_, _, maximum)
        return maximum > 0 and 0 or 0
    end

    function world.cell(_, _, x, y)
        if y ~= 1 or x < 1 or x > 12 then
            return nil
        end

        if x == door then
            return terrain.DNGN_CLOSED_DOOR
        end

        return terrain.DNGN_FLOOR
    end

    return world
end

function test.run(ctx)
    local player = ctx:create()
    local origin = { level_id = 1, x = 1, y = 1 }
    local world = corridor(ctx, player)

    ctx:add(player, component.POSITION, origin)
    harness.equal(noise.adjust(world, origin, 5), 5,
        "ordinary noise preserves its loudness")

    local sound = noise.propagate(world, origin, 5)
    harness.truthy(noise.at(sound, 6, 1) >= 1000,
        "loudness five reaches five floor cells away")
    harness.equal(noise.at(sound, 7, 1), 0,
        "loudness five dies before the sixth floor cell")

    world = corridor(ctx, player, 3)
    sound = noise.propagate(world, origin, 5)
    harness.equal(noise.at(sound, 4, 1), 0,
        "closed doors attenuate sound eight times faster")

    records.grant_acquired(world, player,
        mutations.MUT_NOISE_DAMPENING, 1)
    harness.equal(noise.adjust(world, origin, 5), 3,
        "noise dampening halves visible sounds with source rounding")

    local monster = ctx:create()
    ctx:add(monster, component.AI, { behavior = "wander" })
    ctx:add(monster, component.POSITION, {
        level_id = 1,
        x = 3,
        y = 1,
    })
    ctx:add(monster, component.HEALTH, {
        current = 5,
        max = 5,
    })

    world = corridor(ctx, player, nil, false)
    noise.emit(world, origin, 5, player)
    harness.equal(ctx:get(monster, component.AI).target_x, 1,
        "a heard source outside player sight draws wandering monsters")

    ctx:add(player, component.PLAYER_STATUS, {
        silence_aut = 100,
    })
    harness.equal(noise.emit(world, origin, 5, player), 0,
        "silence suppresses sound at its origin")
end

return test
