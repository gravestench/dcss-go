-- The Wastes occupy a bounded positive source coordinate square. They
-- use a rapidly changing cellular seed but collapse every wall material
-- to ordinary rock, making them sparser than the mixed outer Abyss.
local chaos = require("policy.generation.abyss.roiling_chaos")
local terrain = require("constants.terrain")
local worley = require("policy.generation.abyss.worley")

local wastes = {}

-- The source's offset/3 z scale makes these rock patches morph much
-- faster than the other region layouts.
function wastes.sample(ctx, x, y, depth)
    -- Source offset is uint32, so dividing it by the integer three
    -- truncates before conversion to the cellular z coordinate.
    local cellular = ctx:worley(x, y, math.floor(depth / 3))
    local feature, static_change = chaos.sample(ctx,
        x, y, depth, cellular.id[1], 10)
    local change = worley.change_point(cellular, 3, depth)

    if feature ~= terrain.DNGN_FLOOR then
        feature = terrain.DNGN_ROCK_WALL
    end

    return feature, math.min(static_change, change)
end

return wastes
