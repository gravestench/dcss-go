local harness = require("tests.harness")
local component = require("constants.component")
local ids = require("ids.clouds")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local test = {}

function test.run()
    local field = require("policy.clouds.field")
    local feature = terrain.DNGN_FLOOR
    local cloud = {
        kind_id = ids.CLOUD_RAIN,
        level_id = 1,
        x = 3,
        y = 2,
        decay_aut = 10,
        spread_rate = 0,
        source_actor_id = 0,
        kill_category = "KC_OTHER",
        killer_type = "KILL_MISC",
        opaque = false,
    }
    local marker
    local ctx = {}

    function ctx:query(kinds)
        if kinds[1] == component.WORLD_CLOUD then
            return cloud and { 11 } or {}
        end

        if kinds[1] == component.TEMPORARY_TERRAIN then
            return marker and { 12 } or {}
        end

        error("unexpected component query")
    end

    function ctx:get(entity)
        if entity == 11 then
            return cloud
        end

        return marker
    end

    function ctx:destroy(entity)
        if entity == 11 then
            cloud = nil
        end
    end

    function ctx:create()
        return 12
    end

    function ctx:add(_, kind, state)
        harness.equal(kind, component.TEMPORARY_TERRAIN,
            "rain uses shared timed terrain")
        marker = state
    end

    function ctx:cell()
        return feature
    end

    function ctx:set_cell(_, _, _, next_feature)
        feature = next_feature
    end

    function ctx:aut()
        return 100
    end

    function ctx:random(stream, bound)
        harness.equal(stream, streams.CLOUDS, "rain uses cloud RNG")
        harness.truthy(bound == 5 or bound == 501,
            "rain chance or terrain duration draw")

        return 0
    end

    field.advance(ctx, {
        level_id = 1,
        elapsed_aut = 10,
    })

    harness.falsy(cloud, "expired rain cloud is removed")
    harness.equal(feature, terrain.DNGN_SHALLOW_WATER,
        "one-in-five rain roll floods floor")
    harness.equal(marker.expires_aut, 600,
        "minimum 500 AUT flood is saved")
end

return test
