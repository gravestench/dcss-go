-- None sentinel cannot become saved cloud.

local harness = require("tests.harness")
local component = require("constants.component")
local ids = require("ids.clouds")
local streams = require("constants.rng_streams")
local terrain = require("content.terrain_features")

local test = {}

-- Keep cloud entities in a sorted local store so replacement and selector
-- tests cannot depend on Lua table iteration order.
local function context()
    local state = {}
    local next_entity = 100
    local context = {
        feature = terrain.vault_terrain.DNGN_FLOOR,
        draw = 0,
    }

    -- Enumerate saved cloud entities so placement checks existing occupants
    -- rather than assuming the target cell is empty.
    function context:query(required)
        if required[1] == component.MONSTER_STILL_WINDS then
            return self.wind and { 99 } or {}
        end

        if required[1] ~= component.WORLD_CLOUD then
            return {}
        end

        local entities = {}

        for entity in pairs(state) do
            entities[#entities + 1] = entity
        end

        table.sort(entities)

        return entities
    end

    -- Read the fixture's saved cloud record for overlap and merge decisions.
    function context:get(entity, kind)
        if entity == 99 then
            if kind == component.MONSTER_STILL_WINDS then
                return { remaining_aut = 30 }
            end

            if kind == component.POSITION then
                return { level_id = 1, x = 1, y = 1 }
            end

            if kind == component.HEALTH then
                return { current = 1, max = 1 }
            end
        end

        return state[entity]
    end

    -- Allocate distinct cloud IDs so the test can tell a new cloud from a
    -- refreshed existing one.
    function context:create()
        next_entity = next_entity + 1

        return next_entity
    end

    -- Store only the production cloud component on a new entity, checking
    -- that placement does not write an unrelated schema.
    function context:add(entity, kind, value)
        harness.equal(kind, component.WORLD_CLOUD, "saved cloud schema")
        state[entity] = value
    end

    -- Persist refreshes to an existing cloud and check the same schema as
    -- creation, making a merge visible in saved state.
    function context:set(entity, kind, value)
        harness.equal(kind, component.WORLD_CLOUD, "saved cloud schema")
        state[entity] = value
    end

    -- Remove an overwritten cloud from the fixture so replacement leaves
    -- one occupant at the target cell.
    function context:destroy(entity)
        state[entity] = nil
    end

    -- Switch between rock and open terrain without a full map, isolating the
    -- rule that clouds cannot occupy a blocking wall.
    function context:walkable()
        return self.feature ~= terrain.vault_terrain.DNGN_ROCK_WALL
    end

    -- Give placement the same feature used by walkability and terrain-based
    -- cloud restrictions in this scenario.
    function context:cell()
        return self.feature
    end

    -- Identify the fixture player when cloud ownership affects attribution.
    function context:player()
        return 1
    end

    -- Preserve simple fixture IDs when production code records cloud owner
    -- or source references.
    function context:id(entity)
        return entity
    end

    -- Present a stationary occupant so placement can check actor-related
    -- restrictions without creating a full ECS actor.
    function context:actor_at()
        return 7
    end

    -- Return one chosen cloud draw while asserting the dedicated stream and
    -- legal bound, making selector changes visible without a seed.
    function context:random(stream, bound)
        harness.equal(stream, streams.CLOUDS, "cloud selector stream")
        harness.truthy(self.draw < bound, "selector draw in range")

        return self.draw
    end

    return context
end

-- Probe blocked, merged, replaced, and attributed clouds through one fixture
-- so all cases inspect the same saved placement contract.
function test.run()
    local placement = require("policy.clouds.placement")
    local ctx = context()

    harness.falsy(placement.place(ctx, ids.CLOUD_FIRE, 1, 1, 2, 2, 0),
        "zero duration cannot place")

    -- A weaker clear cloud cannot evict opaque smoke, but stronger opaque
    -- smoke replaces it in place without creating a second cell occupant.
    local first = placement.place(ctx, ids.CLOUD_BLACK_SMOKE,
        1, 1, 2, 2, 30)
    local entity, state = placement.at(ctx, 1, 2, 2)

    harness.equal(entity, first, "cloud occupies its cell")
    harness.truthy(state.opaque, "black smoke blocks sight")
    harness.equal(state.decay_aut, 30, "duration stored as remaining AUT")

    harness.falsy(placement.place(ctx, ids.CLOUD_FIRE,
        1, 1, 2, 2, 20), "opaque harmless cloud resists clear cloud")

    local stronger = placement.place(ctx, ids.CLOUD_GREY_SMOKE,
        1, 1, 2, 2, 20)

    harness.equal(stronger, first, "replacement keeps one cloud entity")
    harness.equal(placement.at(ctx, 1, 2, 2), first,
        "replacement leaves one cloud per cell")
    harness.truthy(ctx:get(first).opaque,
        "opaque smoke replaces opaque harmless smoke")

    -- Replacing steam with fire must refresh the saved opacity cache.
    local steam = placement.place(ctx, ids.CLOUD_STEAM,
        1, 1, 6, 2, 20)
    local clear = placement.place(ctx, ids.CLOUD_FIRE,
        1, 1, 6, 2, 20)

    harness.equal(clear, steam, "steam is replaceable by clear fire")
    harness.falsy(ctx:get(steam).opaque,
        "opaque to clear replacement updates cached opacity")

    -- Ink is terrain-gated while random smoke resolves to a concrete kind.
    ctx.feature = terrain.vault_terrain.DNGN_FLOOR
    harness.falsy(placement.place(ctx, ids.CLOUD_INK,
        1, 1, 3, 2, 20), "ink needs water")

    ctx.feature = terrain.vault_terrain.DNGN_SHALLOW_WATER
    harness.truthy(placement.place(ctx, ids.CLOUD_INK,
        1, 1, 3, 2, 20), "ink may occupy water")

    ctx.draw = 2
    local smoke = placement.place(ctx, "CLOUD_RANDOM_SMOKE",
        1, 1, 4, 2, 20)

    harness.equal(ctx:get(smoke).kind_id, ids.CLOUD_BLACK_SMOKE,
        "random smoke resolves once in source order")

    -- Actor occupancy does not block placement; sanctuary and still winds
    -- then apply distinct harmful-cloud and vortex exceptions.
    harness.truthy(placement.place(ctx, ids.CLOUD_DUST,
        1, 1, 7, 2, 20), "an occupied actor does not block clouds")

    harness.falsy(placement.place(ctx, ids.CLOUD_FIRE,
        1, 1, 8, 2, 20, { sanctuary = true }),
        "sanctuary blocks harmful clouds")

    harness.truthy(placement.place(ctx, ids.CLOUD_DUST,
        1, 1, 8, 2, 20, { sanctuary = true }),
        "sanctuary allows harmless clouds")

    ctx.wind = true
    harness.falsy(placement.place(ctx, ids.CLOUD_FIRE,
        1, 1, 9, 2, 20),
        "still winds blocks ordinary clouds")

    harness.truthy(placement.place(ctx, ids.CLOUD_VORTEX,
        1, 1, 9, 2, 20),
        "vortex is the still winds exception")
    ctx.wind = false

    -- Summoner allegiance is copied into cloud kill credit for later damage.
    local get = ctx.get

    -- Expose a friendly summon on the target cell; placement must use its
    -- allegiance when deciding whether a cloud can affect that occupant.
    function ctx:get(entity, kind)
        if entity == 2 and kind == component.SUMMON then
            return { hostile = false }
        end

        return get(self, entity, kind)
    end

    local friendly = placement.place(ctx, ids.CLOUD_POISON,
        2, 1, 11, 2, 20)
    local credit = ctx:get(friendly, component.WORLD_CLOUD)

    harness.equal(credit.kill_category, "KC_FRIENDLY",
        "friendly monster cloud preserves source allegiance")

    -- Selector sentinels may request a type but cannot be persisted as one.
    local okay = pcall(placement.place, ctx, "CLOUD_NONE",
        1, 1, 5, 2, 20)

    harness.falsy(okay, "none sentinel cannot become saved cloud")

    for _, selector in ipairs({
        "CLOUD_RANDOM",
        "CLOUD_DEBUGGING",
    }) do
        local selected = pcall(placement.place, ctx,
            selector, 1, 1, 5, 2, 20)

        harness.falsy(selected, "non-placeable selector is rejected")
    end
end

return test
