local harness = require("tests.harness")
local component = require("constants.component")
local ids = require("ids.clouds")
local streams = require("constants.rng_streams")
local terrain = require("content.terrain_features")

local test = {}

local function context()
    local state = {}
    local next_entity = 100
    local context = {
        feature = terrain.vault_terrain.DNGN_FLOOR,
        draw = 0,
    }

    function context:query()
        local entities = {}

        for entity in pairs(state) do
            entities[#entities + 1] = entity
        end

        table.sort(entities)

        return entities
    end

    function context:get(entity)
        return state[entity]
    end

    function context:create()
        next_entity = next_entity + 1

        return next_entity
    end

    function context:add(entity, kind, value)
        harness.equal(kind, component.WORLD_CLOUD, "saved cloud schema")
        state[entity] = value
    end

    function context:set(entity, kind, value)
        harness.equal(kind, component.WORLD_CLOUD, "saved cloud schema")
        state[entity] = value
    end

    function context:destroy(entity)
        state[entity] = nil
    end

    function context:walkable()
        return self.feature ~= terrain.vault_terrain.DNGN_ROCK_WALL
    end

    function context:cell()
        return self.feature
    end

    function context:player()
        return 1
    end

    function context:id(entity)
        return entity
    end

    function context:actor_at()
        return 7
    end

    function context:random(stream, bound)
        harness.equal(stream, streams.CLOUDS, "cloud selector stream")
        harness.truthy(self.draw < bound, "selector draw in range")

        return self.draw
    end

    return context
end

function test.run()
    local placement = require("policy.clouds.placement")
    local ctx = context()

    harness.falsy(placement.place(ctx, ids.CLOUD_FIRE, 1, 1, 2, 2, 0),
        "zero duration cannot place")

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

    local steam = placement.place(ctx, ids.CLOUD_STEAM,
        1, 1, 6, 2, 20)
    local clear = placement.place(ctx, ids.CLOUD_FIRE,
        1, 1, 6, 2, 20)

    harness.equal(clear, steam, "steam is replaceable by clear fire")
    harness.falsy(ctx:get(steam).opaque,
        "opaque to clear replacement updates cached opacity")

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

    harness.truthy(placement.place(ctx, ids.CLOUD_DUST,
        1, 1, 7, 2, 20), "an occupied actor does not block clouds")

    harness.falsy(placement.place(ctx, ids.CLOUD_FIRE,
        1, 1, 8, 2, 20, { sanctuary = true }),
        "sanctuary blocks harmful clouds")

    harness.truthy(placement.place(ctx, ids.CLOUD_DUST,
        1, 1, 8, 2, 20, { sanctuary = true }),
        "sanctuary allows harmless clouds")

    harness.falsy(placement.place(ctx, ids.CLOUD_FIRE,
        1, 1, 9, 2, 20, { still_winds = true }),
        "still winds blocks ordinary clouds")

    harness.truthy(placement.place(ctx, ids.CLOUD_VORTEX,
        1, 1, 9, 2, 20, { still_winds = true }),
        "vortex is the still winds exception")

    local get = ctx.get

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
