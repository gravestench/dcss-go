-- Ice Cave's easy/hard choice and frost messages stay in Ice Cave Lua;
-- this entry declares its temporary portal features and marker owner.
local portal = require("policy.world.ice_cave.portal")
local terrain = require("constants.terrain")
local travel = require("policy.world.ice_cave.travel")

local handler = {
    id = "ice_cave",
    features = {
        terrain.DNGN_ENTER_ICE_CAVE,
        terrain.DNGN_EXIT_ICE_CAVE,
    },
}

-- Forward the current source stair to Ice Cave travel.
function handler.prepare(ctx, request)
    return travel.prepare(ctx, request.position, request.downstairs)
end

-- Claim only an Ice Cave source-position timer marker.
function handler.is_marker(record)
    return portal.is_marker(record)
end

-- Save the clock and difficulty on the existing Akara gate.
function handler.materialize(ctx, level, record)
    return portal.materialize(ctx, level, record)
end

return handler
