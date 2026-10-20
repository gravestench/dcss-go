-- Boris and Natasha are the source exceptions to ordinary run-wide unique
-- claims. Exercise their lives through the real death system and ECS stores.
local component = require("constants.component")
local death = require("systems.actor_death")
local factory = require("policy.population.factory")
local harness = require("tests.harness")
local history = require("policy.population.unique_history")
local items = require("ids.items")
local monsters = require("ids.monsters")
local branches = require("ids.branches")
local replacement = require("policy.population.boris_replacement")
local save_monsters = require("policy.save.monsters")
local terrain = require("constants.terrain")

local test = {}

-- Use actual ECS actors, inventory, and components. The small open level
-- lets the source distance check choose a deterministic safe revival cell.
local function world_context(ctx)
    local world = setmetatable({}, { __index = ctx })
    local player = ctx:create()

    ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
        pan_states = {},
        boris_killed = false,
    })

    -- Unique history is owned by the same player across both lifecycles.
    function world:player()
        return player
    end

    -- Zero draws choose the first legal cell; a test override can reject
    -- Boris's one-in-six new-level chance without altering other streams.
    function world:random(_, bound)
        harness.truthy(bound > 0, "invalid revival random bound")

        if bound == 6 and self.boris_chance then
            return self.boris_chance
        end

        return 0
    end

    -- Both source monsters can stand anywhere on this open fixture level.
    function world:walkable()
        return true
    end

    -- The source revival search accepts only ordinary Dungeon floor.
    function world:cell()
        if self.no_revival_cell then
            return terrain.DNGN_ROCK_WALL
        end

        return terrain.DNGN_FLOOR
    end

    -- The test has enough distant cells for Natasha to revive twice.
    function world:level_size()
        if self.no_revival_cell then
            return 1, 1
        end

        return 30, 30
    end

    -- A Depths floor is one of Boris's four source replacement branches.
    function world:level_branch()
        return self.branch_id or branches.BRANCH_DEPTHS
    end

    -- There are no no-teleport markers in this open fixture.
    function world:marker_property()
        return nil
    end

    -- Read actual actor positions so the reviver cannot stack actors.
    function world:actor_at(level_id, x, y)
        for _, entity in ipairs(ctx:query({ component.ACTOR, component.POSITION })) do
            local position = ctx:get(entity, component.POSITION)

            if position.level_id == level_id and position.x == x and
                position.y == y then
                return entity
            end
        end

        return nil
    end

    -- Production placement creates the actor's saved position.
    function world:place_actor(entity, level_id, x, y)
        ctx:add(entity, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    -- The test world has no separate Go occupancy grid to update.
    function world:remove_actor()
    end

    return world
end

-- Find a living unique by its catalog kind after the old body is removed.
local function living(ctx, kind_id)
    for _, entity in ipairs(ctx:query({ component.ACTOR, component.HEALTH })) do
        local actor = ctx:get(entity, component.ACTOR)
        local health = ctx:get(entity, component.HEALTH)

        if actor.kind_id == kind_id and health.current > 0 then
            return entity
        end
    end

    return nil
end

-- Use actor.death so item drop, claim release, reincarnation, and cleanup
-- happen in the same order as a normal killed monster.
local function kill(ctx, world, entity)
    local health = ctx:get(entity, component.HEALTH)

    health.current = 0
    ctx:set(entity, component.HEALTH, health)
    death.update(world)
end

-- If there is nowhere safe to revive, the source destroys Natasha's
-- inventory and frees her unique claim for a later placement.
local function natasha_without_safe_cell(ctx, world)
    local actor = factory.spawn(world, monsters.MONS_NATASHA, 1, 15, 15)
    local carried = ctx:create()

    ctx:add(carried, component.ITEM, {
        kind_id = items.WPN_DAGGER,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(carried, component.CARRIED_BY, { holder = actor })

    world.no_revival_cell = true
    kill(ctx, world, actor)
    world.no_revival_cell = nil

    harness.falsy(ctx:has(carried, component.ITEM),
        "failed Natasha revival left her inventory on the floor")
    harness.falsy(history.seen(world, monsters.MONS_NATASHA),
        "failed Natasha revival retained her unique claim")
end

-- Save validation sees the two exceptional actors as additional generated
-- monsters on one open level, outside its ambient roster budget.
local function save_input()
    return {
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
    }
end

-- Natasha keeps one carried item across her first and second deaths, then
-- loses her revival privilege after the third lifetime.
local function natasha_three_lives(ctx, world)
    local current = factory.spawn(world, monsters.MONS_NATASHA, 1, 15, 15)
    local carried = ctx:create()

    ctx:add(carried, component.ITEM, {
        kind_id = items.WPN_DAGGER,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(carried, component.CARRIED_BY, { holder = current })

    for revives = 1, 2 do
        kill(ctx, world, current)
        current = living(ctx, monsters.MONS_NATASHA)

        harness.truthy(current, "Natasha did not revive")
        harness.equal(ctx:get(current, component.UNIQUE_REVIVAL).revives,
            revives, "Natasha revival count")
        harness.equal(ctx:get(carried, component.CARRIED_BY).holder,
            current, "Natasha lost her carried item")
        harness.truthy(history.seen(world, monsters.MONS_NATASHA),
            "revived Natasha lost unique claim")
    end

    ctx:set(current, component.UNIQUE_REVIVAL, {
        revives = 3,
    })
    harness.falsy(pcall(save_monsters.run, world, save_input()),
        "impossible Natasha revival count passed restore validation")
    ctx:set(current, component.UNIQUE_REVIVAL, {
        revives = 2,
    })

    kill(ctx, world, current)
    harness.falsy(living(ctx, monsters.MONS_NATASHA),
        "Natasha revived beyond her third life")
    harness.truthy(history.seen(world, monsters.MONS_NATASHA),
        "final Natasha death reopened unique placement")
end

-- Boris's death releases the active claim but records the earlier kill.
-- One successful Depths entry chance creates another claimed actor.
local function boris_can_return(ctx, world)
    local first = factory.spawn(world, monsters.MONS_BORIS, 1, 20, 20)

    kill(ctx, world, first)
    harness.falsy(history.seen(world, monsters.MONS_BORIS),
        "dead Boris still blocks replacement")
    harness.truthy(history.boris_killed(world),
        "Boris's kill was not saved")

    world.branch_id = branches.BRANCH_DUNGEON
    harness.equal(replacement.place(world, {
        id = 1,
        width = 30,
        height = 30,
    }, {}), 0, "Boris returned in an ineligible branch")

    world.branch_id = branches.BRANCH_DEPTHS
    world.boris_chance = 1
    harness.equal(replacement.place(world, {
        id = 1,
        width = 30,
        height = 30,
    }, {}), 0, "Boris ignored his one-in-six chance")

    world.boris_chance = nil
    harness.equal(replacement.place(world, {
        id = 1,
        width = 30,
        height = 30,
    }, {}), 1, "Boris was not replaced on an eligible new level")
    local current = living(ctx, monsters.MONS_BORIS)

    harness.truthy(current,
        "replaced Boris has no living actor")
    ctx:set(current, component.UNIQUE_REPLACEMENT, {
        kind_id = monsters.MONS_RAT,
    })
    harness.falsy(pcall(save_monsters.run, world, save_input()),
        "forged Boris replacement passed restore validation")
    ctx:set(current, component.UNIQUE_REPLACEMENT, {
        kind_id = monsters.MONS_BORIS,
    })
end

-- Cover both exceptional lifecycles without a test-only claim ledger.
function test.run(ctx)
    local world = world_context(ctx)

    natasha_without_safe_cell(ctx, world)
    natasha_three_lives(ctx, world)
    boris_can_return(ctx, world)
    history.validate(ctx:get(world:player(),
        component.PLAYER_UNIQUE_HISTORY))
    save_monsters.run(world, save_input())
end

return test
