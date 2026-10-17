local harness = require("tests.harness")
local component = require("constants.component")
local ids = require("ids.clouds")
local terrain = require("constants.terrain")

local test = {}

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

    function ctx:query(kind)
        harness.equal(kind[1], component.WORLD_CLOUD,
            "field queries production cloud schema")

        return { 11, 12, 13 }
    end

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

    function ctx:player()
        return 1
    end

    function ctx:id(entity)
        return entity
    end

    function ctx:visible()
        return false
    end

    function ctx:set(entity, kind, state)
        harness.equal(kind, component.WORLD_CLOUD,
            "field updates production cloud schema")
        states[entity] = state
    end

    function ctx:destroy(entity)
        states[entity] = nil
    end

    function ctx:cell()
        return terrain.DNGN_FLOOR
    end

    return ctx, states
end

function test.run()
    local field = require("policy.clouds.field")
    local ctx, states = context()

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

    field.advance(ctx, {
        level_id = 1,
        elapsed_aut = 10,
    })

    harness.falsy(states[13],
        "player-made clear cloud outside sight dissipates immediately")
end

return test
