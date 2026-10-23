-- The shared temporary-portal catalog discovers this domain by file
-- path. Feature ownership and marker ownership stay with Wizard Lab,
-- so another temporary portal needs no central navigation branch.
local portal = require("policy.world.wizlab.portal")
local terrain = require("constants.terrain")
local travel = require("policy.world.wizlab.travel")

local handler = {
    id = "wizlab",
    features = {
        terrain.DNGN_ENTER_WIZLAB,
        terrain.DNGN_EXIT_WIZLAB,
    },
}

-- The room's entry and exit arches share one travel owner.
function handler.prepare(ctx, request)
    return travel.prepare(ctx, request.position, request.downstairs)
end

-- Only timed markers from Wizard Lab entrance maps belong here.
function handler.is_marker(record)
    return portal.is_marker(record)
end

-- Materialize after nonportal records have declined this marker.
function handler.materialize(ctx, level, record)
    return portal.materialize(ctx, level, record)
end

return handler
