-- Volcano eruptions are separate from its gate. This registration routes
-- only the timed entrance marker and the two travel arches.
local portal = require("policy.world.volcano.portal")
local terrain = require("constants.terrain")
local travel = require("policy.world.volcano.travel")

local handler = {
    id = "volcano",
    features = {
        terrain.DNGN_ENTER_VOLCANO,
        terrain.DNGN_EXIT_VOLCANO,
    },
}

-- Let Volcano travel decide whether the source clock still permits entry.
function handler.prepare(ctx, request)
    return travel.prepare(ctx, request.position, request.downstairs)
end

-- Keep hazard markers with their separate hazard owner.
function handler.is_marker(record)
    return portal.is_marker(record)
end

-- Create only the saved gate, not the floor's eruption clocks.
function handler.materialize(ctx, level, record)
    return portal.materialize(ctx, level, record)
end

return handler
