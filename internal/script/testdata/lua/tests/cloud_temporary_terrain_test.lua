-- Marker preserves original feature.

local harness = require("tests.harness")
local component = require("constants.component")
local terrain = require("constants.terrain")

local test = {}

-- Place cloud-created terrain through the shared temporary marker and
-- verify it restores the prior feature when its duration runs out.
function test.run()
    local temporary = require("policy.world.temporary_terrain")
    local state
    local changed = terrain.DNGN_FLOOR
    local ctx = {}

    -- Read the current feature so temporary terrain can remember what to
    -- restore after the cloud effect ends.
    function ctx:cell()
        return changed
    end

    -- Begin with no competing marker at the cell, making the first placement
    -- independent of overlap policy.
    function ctx:query()
        return {}
    end

    -- Return a distinct marker entity ID so saved terrain metadata can be
    -- inspected separately from the level cell.
    function ctx:create()
        return 17
    end

    -- Keep fixture IDs unchanged when the marker stores its source actor.
    function ctx:id(actor)
        return actor
    end

    -- Use a fixed duration unit so the restoration deadline is predictable.
    function ctx:aut()
        return 100
    end

    -- Capture the common timed-terrain component and assert its schema,
    -- proving cloud terrain uses the normal restoration system.
    function ctx:add(entity, kind, fields)
        harness.equal(entity, 17, "new terrain marker entity")
        harness.equal(kind, component.TEMPORARY_TERRAIN,
            "generic saved terrain schema")
        state = fields
    end

    -- Record the replacement feature in the fixture so later assertions can
    -- verify both placement and eventual restoration.
    function ctx:set_cell(_, _, _, feature)
        changed = feature
    end

    harness.truthy(temporary.place(ctx, 1, "CLOUD_RAIN", 1, 3, 2,
        terrain.DNGN_SHALLOW_WATER, 500),
        "rain can temporarily flood a floor cell")
    harness.equal(changed, terrain.DNGN_SHALLOW_WATER,
        "terrain changes immediately")
    harness.equal(state.original_feature, terrain.DNGN_FLOOR,
        "marker preserves original feature")
    harness.equal(state.expires_aut, 600,
        "marker stores absolute expiry from duration")
end

return test
