-- Bands from the source catalog must save as linked ECS actors. A dead
-- leader releases those links, while Pikel's marked lemures disappear.
local bands = require("policy.population.bands")
local clouds = require("ids.clouds")
local component = require("constants.component")
local death = require("systems.actor_death")
local factory = require("policy.population.factory")
local harness = require("tests.harness")
local links = require("policy.save.links")
local save_monsters = require("policy.save.monsters")
local monsters = require("ids.monsters")
local species = require("ids.species")
local jobs = require("ids.jobs")
local terrain = require("constants.terrain")
local branches = require("ids.branches")

local test = {}

-- This open ECS fixture keeps only occupancy in a small world proxy.
-- Monster definitions, band choices, and component schemas stay in Lua.
local function world_context(ctx)
    local world = setmetatable({}, { __index = ctx })
    local player = ctx:create()

    ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
        pan_states = {},
        boris_killed = false,
    })

    -- Unique leaders claim the one player-owned run ledger.
    function world:player()
        return player
    end

    -- First outcomes make every source band count and cell repeatable.
    function world:random(_, bound)
        harness.truthy(bound > 0, "invalid band draw")

        return 0
    end

    -- Band placement can use any nearby cell in this open fixture.
    function world:walkable()
        return true
    end

    -- The test isolates source membership rather than line of sight.
    function world:visible()
        return true
    end

    -- Cloud and habitat rules see ordinary Dungeon floor.
    function world:cell()
        return terrain.DNGN_FLOOR
    end

    -- No action time passes between placement and leader death here.
    function world:aut()
        return 0
    end

    -- Read live ECS positions to prevent overlapping band placements.
    function world:actor_at(level_id, x, y)
        for _, entity in ipairs(ctx:query({
            component.ACTOR,
            component.POSITION,
        })) do
            local position = ctx:get(entity, component.POSITION)

            if position.level_id == level_id and position.x == x and
                position.y == y then
                return entity
            end
        end

        return nil
    end

    -- Source placement materializes its position in the real store.
    function world:place_actor(entity, level_id, x, y)
        ctx:add(entity, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    -- Removing grid occupancy deletes the positioned ECS component.
    function world:remove_actor(entity)
        ctx:remove(entity, component.POSITION)
    end

    return world
end

-- Real band creation attaches follower handles to a leader; inspect those
-- handles instead of reconstructing source slots in the test.
local function followers(ctx, leader)
    local result = {}

    for _, entity in ipairs(ctx:query({ component.FOLLOWER })) do
        if ctx:get(entity, component.FOLLOWER).leader == leader then
            result[#result + 1] = entity
        end
    end

    return result
end

-- A normal death runs inventory, death hooks, and actor cleanup in the
-- same phase that the generated Dungeon uses.
local function kill(ctx, world, entity)
    local health = ctx:get(entity, component.HEALTH)

    health.current = 0
    ctx:set(entity, component.HEALTH, health)
    death.update(world)
end

-- Source Pikel marks only his lemures. Their saved origin prevents an
-- unrelated lemure from being dismissed when he dies on another floor.
local function pikel_minions(ctx, world)
    local leader = factory.spawn(world, monsters.MONS_PIKEL,
        1, 15, 15)
    local count = bands.spawn(world, leader, { id = 1 }, {})
    local minions = followers(ctx, leader)

    harness.equal(count, 4, "Pikel source band minimum")
    harness.equal(#minions, count, "Pikel band has ECS links")
    harness.truthy(component.PIKEL_BAND,
        "Pikel band has no shared component ID")
    harness.truthy(component.BAND_ORIGIN,
        "bands have no persistent origin component ID")

    for _, entity in ipairs(minions) do
        harness.truthy(ctx:has(entity, component.PIKEL_BAND),
            "Pikel lemure lacks its saved band origin")
        harness.equal(ctx:get(entity, component.BAND_ORIGIN).leader_kind_id,
            monsters.MONS_PIKEL, "Pikel member's catalog origin")
    end

    links.validate(world)

    local first = minions[1]
    local identity = ctx:get(first, component.ACTOR)

    identity.kind_id = monsters.MONS_RAT
    ctx:set(first, component.ACTOR, identity)
    harness.falsy(pcall(links.validate, world),
        "forged Pikel follower passed link validation")
    identity.kind_id = monsters.MONS_LEMURE
    ctx:set(first, component.ACTOR, identity)

    -- A nonband lemure survives the delayed action, even on this level.
    local independent = factory.spawn(world, monsters.MONS_LEMURE,
        1, 23, 15)

    kill(ctx, world, leader)

    for _, entity in ipairs(minions) do
        harness.falsy(ctx:has(entity, component.ACTOR),
            "Pikel's former minion did not depart")
    end

    harness.truthy(ctx:has(independent, component.ACTOR),
        "an unrelated lemure departed with Pikel's band")
    harness.equal(#ctx:query({ component.WORLD_CLOUD }), count,
        "each departing lemure leaves black smoke")

    for _, entity in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        harness.equal(ctx:get(entity, component.WORLD_CLOUD).kind_id,
            clouds.CLOUD_BLACK_SMOKE, "Pikel cloud kind")
    end

    -- Remove the unrelated fixture actor before validating the remaining
    -- band members as the only saved monsters on this generated floor.
    world:remove_actor(independent, 1)
    ctx:destroy(independent)
end

-- A generic source band also releases its follower references when the
-- leader dies. Its wolves remain ordinary autonomous monsters.
local function generic_band(ctx, world)
    local leader = factory.spawn(world, monsters.MONS_GRUM,
        1, 35, 15)

    bands.spawn(world, leader, { id = 1 }, {})

    local pack = followers(ctx, leader)

    harness.equal(#pack, 2, "Grum has a source wolf pack")
    links.validate(world)
    kill(ctx, world, leader)

    for _, entity in ipairs(pack) do
        harness.truthy(ctx:has(entity, component.ACTOR),
            "ordinary follower died with its leader")
        harness.falsy(ctx:has(entity, component.FOLLOWER),
            "ordinary follower retained a dead leader")
        harness.equal(ctx:get(entity, component.BAND_ORIGIN).leader_kind_id,
            monsters.MONS_GRUM, "orphaned wolf retained its band origin")
    end

    links.validate(world)
    save_monsters.run(world, {
        scenario_id = "generated-dungeon-basic-v1",
        current_aut = 0,
        player_alive = true,
        levels = {
            {
                id = 1,
                branch_id = branches.BRANCH_DUNGEON,
                initial_actors = 100,
            },
        },
    })
end

-- Killing a bound lemure grants no XP and leaves no corpse in source
-- Crawl; Pikel carries a larger reward to account for his minions.
local function marked_minion_has_no_reward(ctx, world)
    local player = world:player()
    local minion = factory.spawn(world, monsters.MONS_LEMURE,
        1, 45, 15)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Band lifecycle test",
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 0,
        y = 0,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
        total_xp = 0,
    })
    ctx:add(player, component.SKILL_TRAINING, {
        available_xp = 0,
        spent_xp = 0,
        cost_level = 1,
        manual = false,
        settings = {},
        recent_practice = {},
        recent_all = {},
    })
    ctx:add(minion, component.PIKEL_BAND, {
        band_member = true,
    })

    ctx:signal("player_kill", minion)
    kill(ctx, world, minion)

    harness.equal(ctx:get(player, component.PROGRESSION).total_xp,
        0, "Pikel minion granted experience")
    harness.equal(#ctx:query({ component.CORPSE }), 0,
        "Pikel minion left a corpse")
end

-- Both named and ordinary bands exercise the same saved link owner.
function test.run(ctx)
    local world = world_context(ctx)

    pikel_minions(ctx, world)
    generic_band(ctx, world)
    marked_minion_has_no_reward(ctx, world)
end

return test
