-- Treasure Trove's saved price remains in the toll and payment policies;
-- this handler binds its source O marker and confirmation-bearing arch.
local portal = require("policy.world.trove.portal")
local terrain = require("constants.terrain")
local travel = require("policy.world.trove.travel")

local handler = {
    id = "trove",
    features = {
        terrain.DNGN_ENTER_TROVE,
        terrain.DNGN_EXIT_TROVE,
    },
}

-- Pass confirmation through unchanged so a stale gate cannot be paid.
function handler.prepare(ctx, request)
    return travel.prepare(ctx, request.position, request.downstairs,
        request.forced, request.target_id)
end

-- A missing or duplicate source toll is rejected before population.
function handler.validate_level(ctx, level)
    return portal.validate_level(ctx, level)
end

-- Claim only a Trove source-position price marker.
function handler.is_marker(record)
    return portal.is_marker(record)
end

-- The price owner rolls once and stores its immutable witness.
function handler.materialize(ctx, level, record)
    return portal.materialize(ctx, level, record)
end

return handler
