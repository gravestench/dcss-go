-- The generic stair command asks this feature owner for the Arena's
-- reciprocal visit. Entry is an Okawaru ability, not a terrain gate.
local terrain = require("constants.terrain")
local travel = require("policy.world.arena.travel")

local handler = {
    id = "arena",
    features = {
        terrain.DNGN_EXIT_ARENA,
    },
}

-- A climb at the authored exit requests a staged return transaction.
function handler.prepare(ctx, request)
    return travel.prepare(ctx, request.position, request.downstairs)
end

-- Duel enters from an ability, so no dungeon marker creates an Arena gate.
function handler.is_marker()
    return false
end

-- An Arena DES has spectators and walls but no timed outside portal clock.
function handler.materialize()
    return nil
end

return handler
