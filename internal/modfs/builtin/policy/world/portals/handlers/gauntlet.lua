-- The layered portal catalog discovers this Gauntlet handler by path.
-- Source marker ownership and travel feature ownership share one domain.
local portal = require("policy.world.gauntlet.portal")
local terrain = require("constants.terrain")
local travel = require("policy.world.gauntlet.travel")

local handler = {
    id = "gauntlet",
    features = {
        terrain.DNGN_ENTER_GAUNTLET,
        terrain.DNGN_EXIT_GAUNTLET,
    },
}

-- Stair intent is interpreted by Lua before the kernel stages a floor.
function handler.prepare(ctx, request)
    return travel.prepare(ctx, request.position, request.downstairs)
end

-- Only the authored Gauntlet entrance can produce this timed gate.
function handler.is_marker(record)
    return portal.is_marker(record)
end

-- Population converts the marker into a saved ECS clock once.
function handler.materialize(ctx, level, record)
    return portal.materialize(ctx, level, record)
end

return handler
