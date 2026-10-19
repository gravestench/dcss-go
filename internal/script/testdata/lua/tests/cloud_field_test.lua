-- Player-made clear cloud outside sight dissipates immediately.

local harness = require("tests.harness")
local component = require("constants.component")
local ids = require("ids.clouds")
local terrain = require("constants.terrain")

local test = {}

-- Two level clouds share the fixture, but only the active level should age.
local function context()
    local states = {
        [11] = {
            kind_id = ids.CLOUD_FIRE,
            level_id = 1,
            x = 2,
            y = 2,
            decay_aut = 20,
            spread_rate = 0,
            opaque = false,
        },
        [12] = {
            kind_id = ids.CLOUD_FIRE,
            level_id = 2,
            x = 2,
            y = 2,
            decay_aut = 20,
            spread_rate = 0,
            opaque = false,
        },
    }
    local ctx = {}

    -- Expose all fixture clouds through the production schema so aging can
    -- visit each one regardless of its current duration.
    function ctx:query(kind)
        harness.equal(kind[1], component.WORLD_CLOUD,
            "field queries production cloud schema")

        return { 11, 12, 13 }
    end

    -- Return player position or the requested cloud state; omitted parts
    -- keep this case focused on field aging and visibility.
    function ctx:get(entity, kind)
        if entity == 1 and kind == component.POSITION then
            return {
                level_id = 1,
                x = 2,
                y = 2,
            }
        end

        return states[entity]
    end

    -- Give field processing a stable observer for message visibility rules.
    function ctx:player()
        return 1
    end

    -- Preserve fixture IDs when cloud records reference their source.
    function ctx:id(entity)
        return entity
    end

    -- Hide clouds from the player so field aging cannot rely on visible
    -- presentation side effects to update saved durations.
    function ctx:visible()
        return false
    end

    -- Persist decremented cloud state and assert the real cloud schema was
    -- written, making duration accounting observable after the tick.
    function ctx:set(entity, kind, state)
        harness.equal(kind, component.WORLD_CLOUD,
            "field updates production cloud schema")
        states[entity] = state
    end

    -- Drop spent cloud entities so the test can distinguish expiry from a
    -- duration that merely reached zero.
    function ctx:destroy(entity)
        states[entity] = nil
    end

    -- Hold terrain at ordinary floor to isolate field timing from feature
    -- specific cloud reactions.
    function ctx:cell()
        return terrain.DNGN_FLOOR
    end

    return ctx, states
end

-- Spend explicit AUT across several clouds and inspect saved survivors,
-- ensuring field ticks respect elapsed time rather than one fixed turn.
function test.run()
    local field = require("policy.clouds.field")
    local ctx, states = context()

    -- The field consumes spent AUT instead of assuming one fixed turn.
    field.advance(ctx, {
        level_id = 1,
        elapsed_aut = 10,
    })

    harness.equal(states[11].decay_aut, 10,
        "active floor cloud ages once by spent AUT")
    harness.equal(states[12].decay_aut, 20,
        "inactive floor cloud remains unchanged")

    states[13] = {
        kind_id = ids.CLOUD_POISON,
        level_id = 1,
        x = 4,
        y = 4,
        decay_aut = 50,
        spread_rate = 0,
        source_actor_id = 1,
        opaque = false,
    }

    -- A player-owned clear cloud outside sight is removed on its next update.
    field.advance(ctx, {
        level_id = 1,
        elapsed_aut = 10,
    })

    harness.falsy(states[13],
        "player-made clear cloud outside sight dissipates immediately")
end

return test
