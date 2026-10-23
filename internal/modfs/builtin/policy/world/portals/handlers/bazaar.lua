-- Bazaar's two source marker constructors and both travel arches belong to
-- one owner. Keeping this file small makes sparse mod replacement explicit.
local portal = require("policy.world.bazaar.portal")
local terrain = require("constants.terrain")
local travel = require("policy.world.bazaar.travel")

local handler = {
    id = "bazaar",
    features = {
        terrain.DNGN_ENTER_BAZAAR,
        terrain.DNGN_EXIT_BAZAAR,
    },
}

-- Forward the original Bazaar decision without copying its timer policy.
function handler.prepare(ctx, request)
    return travel.prepare(ctx, request.position, request.downstairs)
end

-- The Bazaar marker owner recognizes timed and one-way source markers.
function handler.is_marker(record)
    return portal.is_marker(record)
end

-- The same original owner creates the Akara gate after placement.
function handler.materialize(ctx, level, record)
    return portal.materialize(ctx, level, record)
end

return handler
