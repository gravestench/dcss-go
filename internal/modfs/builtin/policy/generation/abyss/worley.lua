-- A Worley mixer assigns each spatial cell a child layout. Its point ID
-- chooses the child, while the gap between two nearest points says when
-- a morphing sample must be revisited. The child stays ordinary Lua.
local constants = require("constants.abyss")
local features = require("policy.generation.abyss.features")

local worley = {}

-- The five-depth safety margin comes from source _get_changepoint.
-- It refreshes a cell shortly before its nearest-point owner changes.
function worley.change_point(sample, scale, depth)
    local gap = sample.distance[2] - sample.distance[1]
    local delta = math.max(1, math.floor(gap * scale) - 5)

    return depth + delta
end

-- Source parity reduces regularity in the region picker. The same ID
-- translates the child coordinates, which keeps seams from lining up.
function worley.mix(ctx, state, x, y, depth, seed, scale, layouts)
    local sample = ctx:worley(x / scale, y / scale,
        depth / constants.WORLEY_OFFSET_SCALE + seed)
    local id = math.floor(sample.id[1] / 4)
    local size = #layouts
    local first = id % size
    local second = math.floor(id / size) % size
    local choice = first

    if sample.id[1] % 4 == 0 then
        choice = math.min(first, second)
    end

    local selected = layouts[(choice + seed) % size + 1]
    local translated_x = features.signed32(x + id)
    local translated_y = features.signed32(y + id)
    local feature, child_change = selected(ctx, state,
        translated_x, translated_y, depth)
    local change = worley.change_point(sample,
        constants.WORLEY_OFFSET_SCALE, depth)

    return feature, math.min(change, child_change)
end

return worley
