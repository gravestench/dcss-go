local component = require("constants.component")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local noise = require("policy.world.noise")
local species = require("ids.species")
local scream = require("systems.character_scream")
local records = require("policy.mutations.records")
local terrain = require("constants.terrain")

local test = {}

local function world_for(ctx, player)
    local world = setmetatable({}, { __index = ctx })
    local shouts = 0
    local visible = true

    function world.player()
        return player
    end

    function world.random()
        return 0
    end

    function world.aut()
        return 0
    end

    function world.visible()
        return visible
    end

    function world.set_visible(value)
        visible = value
    end

    function world.cell(_, _, x, y)
        if x < 1 or x > 12 or y < 1 or y > 3 then
            return nil
        end

        return terrain.DNGN_FLOOR
    end

    function world.emit(_, channel)
        if channel == "mutation" then
            shouts = shouts + 1
        end
    end

    function world.shouts()
        return shouts
    end

    return world
end

function test.run(ctx)
    local player = ctx:create()
    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    local world = world_for(ctx, player)
    records.grant_acquired(world, player, mutations.MUT_SCREAM, 1)
    harness.equal(noise.shout_volume(world, player), 14,
        "Scream raises shout loudness by two per level")

    local monster = ctx:create()
    ctx:add(monster, component.ACTOR, {
        kind_id = monsters.MONS_GOBLIN,
    })
    ctx:add(monster, component.POSITION, {
        level_id = 1,
        x = 5,
        y = 1,
    })
    ctx:add(monster, component.HEALTH, {
        current = 5,
        max = 5,
    })
    ctx:add(monster, component.AI, { behavior = "wander" })

    scream.update(world, player)
    harness.equal(world.shouts(), 1,
        "first sight can trigger an involuntary shout")
    harness.equal(ctx:get(monster, component.AI).behavior, "seek",
        "the shout alerts a monster through sound")

    scream.update(world, player)
    harness.equal(world.shouts(), 1,
        "continuous sight does not repeat the shout")

    world.set_visible(false)
    scream.update(world, player)
    world.set_visible(true)
    scream.update(world, player)
    harness.equal(world.shouts(), 2,
        "a monster coming back into view can trigger another shout")
end

return test
