-- Source unique bands use the same definition-owned profile and ECS links
-- whether their leader came from a vault or ambient population.
local bands = require("policy.population.bands")
local component = require("constants.component")
local factory = require("policy.population.factory")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local terrain = require("constants.terrain")
local streams = require("constants.rng_streams")

local test = {}

-- Use real ECS records but predictable random draws. The position query
-- prevents the fixture from letting two followers occupy the same cell.
local function world_context(ctx)
    local world = setmetatable({}, { __index = ctx })
    local player = ctx:create()

    ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
        pan_states = {},
        boris_killed = false,
    })

    -- Unique follower claims use the same player owner as normal spawning.
    function world:player()
        return player
    end

    -- Choose the first member and cell, except when the duplicate-Dowan
    -- case deliberately asks for Duvessa's maximum two followers.
    function world:random(stream, bound)
        harness.truthy(bound > 0, "band random bound")

        if self.force_large_band and stream == streams.BANDS and
            bound == 2 then
            return 1
        end

        return 0
    end

    -- Terrain is open so the test isolates band membership and occupancy.
    function world:walkable()
        return true
    end

    -- Every nearby follower can see its leader in this tiny fixture.
    function world:visible()
        return true
    end

    -- Source habitat checks see ordinary Dungeon floor.
    function world:cell()
        return terrain.DNGN_FLOOR
    end

    -- Scan real ECS positions to prevent a duplicate occupant.
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

    -- Persist placements as real position components for the later query.
    function world:place_actor(entity, level_id, x, y)
        ctx:add(entity, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    return world
end

-- Inspect actual follower links instead of recreating a parallel band list
-- in the test. Source gear and health still come from the monster catalog.
local function followers(ctx, leader)
    local kinds = {}

    for _, entity in ipairs(ctx:query({ component.FOLLOWER, component.ACTOR })) do
        if ctx:get(entity, component.FOLLOWER).leader == leader then
            kinds[#kinds + 1] = ctx:get(entity, component.ACTOR).kind_id
        end
    end

    return kinds
end

-- Grum repeats his wolf slot, while Polyphemus has a compulsory first
-- catoblepas and then fills the remaining source slots with death yaks.
local function source_slot_shapes(ctx, world)
    local grum = factory.spawn(world, monsters.MONS_GRUM, 1, 10, 10)
    local count = bands.spawn(world, grum, { id = 1 }, {})
    local pack = followers(ctx, grum)

    harness.equal(count, 2, "Grum minimum band size")
    harness.equal(#pack, count, "Grum followers have ECS links")

    for _, kind_id in ipairs(pack) do
        harness.equal(kind_id, monsters.MONS_WOLF, "Grum follower kind")
    end

    local polyphemus = factory.spawn(world,
        monsters.MONS_POLYPHEMUS, 1, 30, 30)
    local herd_count = bands.spawn(world, polyphemus, { id = 1 }, {})
    local herd = followers(ctx, polyphemus)

    harness.equal(herd_count, 3, "Polyphemus minimum band size")
    harness.equal(herd[1], monsters.MONS_CATOBLEPAS,
        "Polyphemus first follower")
    harness.equal(herd[2], monsters.MONS_DEATH_YAK,
        "Polyphemus repeated follower slot")
end

-- Duvessa's source range can request two Dowans, but a named unique may
-- only spawn once. The second slot is skipped without allocating an actor.
local function unique_follower_claim(ctx, world)
    local duvessa = factory.spawn(world, monsters.MONS_DUVESSA, 1, 50, 50)

    world.force_large_band = true

    local count = bands.spawn(world, duvessa, { id = 1 }, {})
    local band = followers(ctx, duvessa)

    harness.equal(count, 1, "Dowan spawned once")
    harness.equal(#band, 1, "Duvessa has one unique follower")
    harness.equal(band[1], monsters.MONS_DOWAN, "Duvessa follower kind")
end

-- Verify distinct source band shapes through production creation and links.
function test.run(ctx)
    local world = world_context(ctx)

    source_slot_shapes(ctx, world)
    unique_follower_claim(ctx, world)
end

return test
