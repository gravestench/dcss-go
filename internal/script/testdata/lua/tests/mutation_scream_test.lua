
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

-- Count involuntary shouts while reading the live player and monster positions.
local function world_for(ctx, player)
    local world = setmetatable({}, { __index = ctx })
    local shouts = 0
    local visible = true

    -- Bind policy ownership to scream fixture actor so player-only branches execute on that entity.
    function world.player()
        return player
    end

    -- Trigger the shout chance on first sight to compare repeated visibility.
    function world.random()
        return 0
    end

    -- Freeze scream world time; the explicit aut argument drives every timer change.
    function world.aut()
        return 0
    end

    -- Make scream sight deterministic while leaving actor positions to the ECS fixture.
    function world.visible()
        return visible
    end

    -- Flip the fixture sight state to test a newly visible versus continuously visible target.
    function world.set_visible(value)
        visible = value
    end

    -- Return scream fixture terrain that gates the environmental branch.
    function world.cell(_, _, x, y)
        if x < 1 or x > 12 or y < 1 or y > 3 then
            return nil
        end

        return terrain.DNGN_FLOOR
    end

    -- Capture scream events separately from the policy state being asserted.
    function world.emit(_, channel)
        if channel == "mutation" then
            shouts = shouts + 1
        end
    end

    -- Read captured shout count without deriving it from unrelated messages.
    function world.shouts()
        return shouts
    end

    return world
end

-- Continuous sight does not repeat the shout.
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
    -- New visibility creates one eligible scream opportunity and emits noise.
    harness.equal(world.shouts(), 1,
        "first sight can trigger an involuntary shout")
    harness.equal(ctx:get(monster, component.AI).behavior, "seek",
        "the shout alerts a monster through sound")

    scream.update(world, player)
    -- Seen-by-player state prevents repeated rolls while visibility is uninterrupted.
    harness.equal(world.shouts(), 1,
        "continuous sight does not repeat the shout")

    world.set_visible(false)
    scream.update(world, player)
    world.set_visible(true)
    scream.update(world, player)
    -- Losing sight clears the marker so reacquisition is a new event.
    harness.equal(world.shouts(), 2,
        "a monster coming back into view can trigger another shout")
end

return test
