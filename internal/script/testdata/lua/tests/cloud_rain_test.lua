-- Minimum 500 AUT flood is saved.

local harness = require("tests.harness")
local component = require("constants.component")
local ids = require("ids.clouds")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local test = {}

-- Age rain over floor with fixed cloud draws and inspect both the new water
-- feature and its temporary-terrain marker.
function test.run()
    local field = require("policy.clouds.field")
    -- A one-in-five zero draw floods floor before the rain cloud expires.
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

    -- Offer the rain cloud while it exists, then an empty result after its
    -- lifetime ends, so field aging can remove it normally.
    function ctx:query(kinds)
        if kinds[1] == component.WORLD_CLOUD then
            return cloud and { 11 } or {}
        end

        if kinds[1] == component.TEMPORARY_TERRAIN then
            return marker and { 12 } or {}
        end

        error("unexpected component query")
    end

    -- Return only the cloud record under its fixture ID, keeping terrain
    -- flooding distinct from unrelated ECS state.
    function ctx:get(entity)
        if entity == 11 then
            return cloud
        end

        return marker
    end

    -- Clear the expired cloud so later assertions can distinguish terrain
    -- left behind from the cloud that caused it.
    function ctx:destroy(entity)
        if entity == 11 then
            cloud = nil
        end
    end

    -- Allocate a separate entity for the temporary water marker rather than
    -- reusing the cloud's ID.
    function ctx:create()
        return 12
    end

    -- Capture the shared timed-terrain component so the test can verify rain
    -- uses ordinary terrain restoration instead of a private timer.
    function ctx:add(_, kind, state)
        harness.equal(kind, component.TEMPORARY_TERRAIN,
            "rain uses shared timed terrain")
        marker = state
    end

    -- Read the current feature after flooding to observe the terrain change.
    function ctx:cell()
        return feature
    end

    -- Record rain's feature replacement, which temporary terrain will later
    -- restore when its marker expires.
    function ctx:set_cell(_, _, _, next_feature)
        feature = next_feature
    end

    -- Use a fixed turn length so cloud and terrain durations are comparable.
    function ctx:aut()
        return 100
    end

    -- Force the rain chance while checking both flood and duration bounds,
    -- catching any extra or wrong-stream draw in this seeded path.
    function ctx:random(stream, bound)
        harness.equal(stream, streams.CLOUDS, "rain uses cloud RNG")
        harness.truthy(bound == 5 or bound == 501,
            "rain chance or terrain duration draw")

        return 0
    end

    -- The timed terrain marker outlives the cloud and keeps its 600 AUT span.
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
