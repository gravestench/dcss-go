-- Ossuary burial timing and room events remain in Ossuary Lua; this small
-- declaration lets the shared portal catalog find its two arches.
local portal = require("policy.world.ossuary.portal")
local terrain = require("constants.terrain")
local travel = require("policy.world.ossuary.travel")

local handler = {
    id = "ossuary",
    features = {
        terrain.DNGN_ENTER_OSSUARY,
        terrain.DNGN_EXIT_OSSUARY,
    },
}

-- Preserve the ordinary Ossuary stair decision and cost.
function handler.prepare(ctx, request)
    return travel.prepare(ctx, request.position, request.downstairs)
end

-- Recognize the source sand-timer marker before population.
function handler.is_marker(record)
    return portal.is_marker(record)
end

-- The existing owner records the portal's lifetime once.
function handler.materialize(ctx, level, record)
    return portal.materialize(ctx, level, record)
end

return handler
