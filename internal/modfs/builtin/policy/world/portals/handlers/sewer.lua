-- Sewer's drain timer and exact return address stay in their source policy;
-- this file declares which map arches and source markers reach it.
local portal = require("policy.world.sewer.portal")
local terrain = require("constants.terrain")
local travel = require("policy.world.sewer.travel")

local handler = {
    id = "sewer",
    features = {
        terrain.DNGN_ENTER_SEWER,
        terrain.DNGN_EXIT_SEWER,
    },
}

-- Forward stair direction to the existing drain travel policy.
function handler.prepare(ctx, request)
    return travel.prepare(ctx, request.position, request.downstairs)
end

-- Claim only the Sewer source timer marker.
function handler.is_marker(record)
    return portal.is_marker(record)
end

-- Give the source marker to the existing Akara drain owner.
function handler.materialize(ctx, level, record)
    return portal.materialize(ctx, level, record)
end

return handler
