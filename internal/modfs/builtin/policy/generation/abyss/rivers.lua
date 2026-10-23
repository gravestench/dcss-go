-- Rivers warp coordinates with source simplex fBM, then inspect a
-- Voronoi border. Only one quarter of regions expose that border;
-- the remaining cells delegate to the ordinary mixed base texture.
local constants = require("constants.abyss")
local terrain = require("constants.terrain")
local worley = require("policy.generation.abyss.worley")

local rivers = {}

-- The supplied fallback is the already composed base layout, so a
-- river cell and its neighboring dry cell share the same terrain owner.
function rivers.sample(ctx, state, x, y, depth, fallback)
    local distorted_x = x + ctx:fbm3(x / 4, y / 4,
        constants.RIVER_SEED, 5) * 3
    local distorted_y = y + ctx:fbm3(x / 4 + 3.7,
        y / 4 + 1.9, constants.RIVER_SEED + 4, 5) * 3
    local cellular = ctx:worley(distorted_x / 90,
        distorted_y / 90, depth / 10000 + constants.RIVER_SEED)
    local change = worley.change_point(cellular, 10000, depth)
    local region = ctx:xor_u32(cellular.id[1],
        cellular.id[2], constants.RIVER_SEED)

    if region % 4 ~= 0 or
        cellular.distance[2] - cellular.distance[1] >= 1.5 / 90 then
        return fallback(ctx, state, x, y, depth)
    end

    local seed = (cellular.id[1] + constants.RIVER_SEED) % 4294967296
    local feature = terrain.DNGN_SHALLOW_WATER

    if ctx:hash3_quotient_mod(x, y, seed, 1, 5) == 0 then
        feature = terrain.DNGN_DEEP_WATER
    end

    if ctx:hash3_quotient_mod(x, y, seed, 1, 23) == 0 then
        feature = terrain.DNGN_TREE
    end

    return feature, change
end

return rivers
