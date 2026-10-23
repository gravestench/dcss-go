-- Source Column and Diamond layouts are the four fixed shapes mixed
-- into broader Abyss textures. Their wall palette is nine weighted slots:
-- four stone, three rock, one crystal, and one metal.
local terrain = require("constants.terrain")
local constants = require("constants.abyss")

local features = {}

local walls = {
    terrain.DNGN_STONE_WALL,
    terrain.DNGN_STONE_WALL,
    terrain.DNGN_STONE_WALL,
    terrain.DNGN_STONE_WALL,
    terrain.DNGN_ROCK_WALL,
    terrain.DNGN_ROCK_WALL,
    terrain.DNGN_ROCK_WALL,
    terrain.DNGN_CRYSTAL_WALL,
    terrain.DNGN_METAL_WALL,
}

-- NewAbyss indexes this palette directly with its cellular point ID.
function features.wall_at_slot(slot)
    return walls[slot % #walls + 1]
end

-- Source coordinate and point-ID addition wraps as a signed 32-bit cell.
-- Lua can calculate the modulo exactly for the IDs used by these layouts.
function features.signed32(value)
    local wrapped = value % 4294967296

    if wrapped >= 2147483648 then
        return wrapped - 4294967296
    end

    return wrapped
end

-- Hashing is done in Go because a source 64-bit product loses bits in
-- Lua numbers; Lua owns the probability and terrain chosen from it.
function features.pseudorandom_wall(ctx, x, y, seed, divisor)
    local slot = ctx:hash3_quotient_mod(x, y, seed, divisor or 1, #walls)

    return features.wall_at_slot(slot)
end

-- The source absolute coordinate grid is intentionally anchored to the
-- unbounded world. Changing the modulus would move whole columns.
function features.column(ctx, x, y, depth, width, spacing)
    local size = width + spacing
    local column_x = math.abs(x) % size
    local column_y = math.abs(y) % size

    if column_x < width and column_y < width then
        local feature = features.pseudorandom_wall(ctx,
            math.modf(x / size), math.modf(y / size), 2)

        return feature, depth + constants.STATIC_CHANGE
    end

    return terrain.DNGN_FLOOR, depth + constants.STATIC_CHANGE
end

-- Two Diamond configurations produce a different wall fraction while
-- retaining the same source hash per diamond cell.
function features.diamond(ctx, x, y, depth, width, spacing)
    local half_cell = width + spacing
    local size = half_cell * 2
    local local_x = math.abs(math.abs(x) % size - half_cell)
    local local_y = math.abs(math.abs(y) % size - half_cell)

    if local_x + local_y < width then
        local feature = features.pseudorandom_wall(ctx,
            math.modf(x / width), math.modf(y / width), 2)

        return feature, depth + constants.STATIC_CHANGE
    end

    return terrain.DNGN_FLOOR, depth + constants.STATIC_CHANGE
end

return features
