local harness = require("tests.harness")
local component = require("constants.component")
local terrain = require("constants.terrain")

local test = {}

function test.run()
    local temporary = require("policy.world.temporary_terrain")
    local state
    local changed = terrain.DNGN_FLOOR
    local ctx = {}

    function ctx:cell()
        return changed
    end

    function ctx:query()
        return {}
    end

    function ctx:create()
        return 17
    end

    function ctx:id(actor)
        return actor
    end

    function ctx:aut()
        return 100
    end

    function ctx:add(entity, kind, fields)
        harness.equal(entity, 17, "new terrain marker entity")
        harness.equal(kind, component.TEMPORARY_TERRAIN,
            "generic saved terrain schema")
        state = fields
    end

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
