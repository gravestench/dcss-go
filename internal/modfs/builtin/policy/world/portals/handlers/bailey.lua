-- The portcullis theme and timer stay in Bailey policy. Its catalog entry
-- claims only Bailey features and source markers.
local portal = require("policy.world.bailey.portal")
local terrain = require("constants.terrain")
local travel = require("policy.world.bailey.travel")

local handler = {
    id = "bailey",
    features = {
        terrain.DNGN_ENTER_BAILEY,
        terrain.DNGN_EXIT_BAILEY,
    },
}

-- Reuse Bailey's verified staging and return decisions.
function handler.prepare(ctx, request)
    return travel.prepare(ctx, request.position, request.downstairs)
end

-- Match the authored Bailey portcullis marker.
function handler.is_marker(record)
    return portal.is_marker(record)
end

-- Materialize one saved Bailey gate from that marker.
function handler.materialize(ctx, level, record)
    return portal.materialize(ctx, level, record)
end

return handler
