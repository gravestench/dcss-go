-- The outer Abyss borrows one already generated ordinary floor. This
-- layout does not copy stairs, altars, shops, or transporters as live
-- destinations. Cells eroded to nil fall back to the river texture.
local terrain = require("constants.terrain")
local constants = require("constants.abyss")

local borrowed = {}

local substituted = {
    [terrain.DNGN_SEALED_DOOR] = terrain.DNGN_CLOSED_DOOR,
    [terrain.DNGN_SEALED_CLEAR_DOOR] = terrain.DNGN_CLOSED_CLEAR_DOOR,
    [terrain.DNGN_PERMAROCK_WALL] = terrain.DNGN_ROCK_WALL,
    [terrain.DNGN_CLEAR_PERMAROCK_WALL] =
        terrain.DNGN_CLEAR_ROCK_WALL,
    [terrain.DNGN_SLIMY_WALL] = terrain.DNGN_CRYSTAL_WALL,
    [terrain.DNGN_ENDLESS_SALT] = terrain.DNGN_FLOOR,
    [terrain.DNGN_OPEN_SEA] = terrain.DNGN_DEEP_WATER,
    [terrain.DNGN_LAVA_SEA] = terrain.DNGN_LAVA,
    [terrain.DNGN_ENTER_SHOP] = terrain.DNGN_FLOOR,
}

local gates = {
    [terrain.DNGN_ENTER_BAZAAR] = true,
    [terrain.DNGN_EXIT_BAZAAR] = true,
    [terrain.DNGN_ENTER_SEWER] = true,
    [terrain.DNGN_EXIT_SEWER] = true,
    [terrain.DNGN_ENTER_OSSUARY] = true,
    [terrain.DNGN_EXIT_OSSUARY] = true,
    [terrain.DNGN_ENTER_WIZLAB] = true,
    [terrain.DNGN_EXIT_WIZLAB] = true,
    [terrain.DNGN_ENTER_DESOLATION] = true,
    [terrain.DNGN_EXIT_DESOLATION] = true,
    [terrain.DNGN_ENTER_GAUNTLET] = true,
    [terrain.DNGN_EXIT_GAUNTLET] = true,
    [terrain.DNGN_ENTER_BAILEY] = true,
    [terrain.DNGN_EXIT_BAILEY] = true,
    [terrain.DNGN_ENTER_ICE_CAVE] = true,
    [terrain.DNGN_EXIT_ICE_CAVE] = true,
    [terrain.DNGN_ENTER_VOLCANO] = true,
    [terrain.DNGN_EXIT_VOLCANO] = true,
    [terrain.DNGN_ENTER_TROVE] = true,
    [terrain.DNGN_EXIT_TROVE] = true,
    [terrain.DNGN_ENTER_PANDEMONIUM] = true,
    [terrain.DNGN_TRANSIT_PANDEMONIUM] = true,
    [terrain.DNGN_EXIT_PANDEMONIUM] = true,
    [terrain.DNGN_EXIT_THROUGH_ABYSS] = true,
    [terrain.DNGN_ENTER_HELL] = true,
    [terrain.DNGN_EXIT_HELL] = true,
    [terrain.DNGN_ENTER_DIS] = true,
    [terrain.DNGN_EXIT_DIS] = true,
    [terrain.DNGN_ENTER_GEHENNA] = true,
    [terrain.DNGN_EXIT_GEHENNA] = true,
    [terrain.DNGN_ENTER_COCYTUS] = true,
    [terrain.DNGN_EXIT_COCYTUS] = true,
    [terrain.DNGN_ENTER_TARTARUS] = true,
    [terrain.DNGN_EXIT_TARTARUS] = true,
}

local solid = {
    [terrain.DNGN_ROCK_WALL] = true,
    [terrain.DNGN_STONE_WALL] = true,
    [terrain.DNGN_PERMAROCK_WALL] = true,
    [terrain.DNGN_CLEAR_ROCK_WALL] = true,
    [terrain.DNGN_CLEAR_STONE_WALL] = true,
    [terrain.DNGN_CLEAR_PERMAROCK_WALL] = true,
    [terrain.DNGN_METAL_WALL] = true,
    [terrain.DNGN_CRYSTAL_WALL] = true,
    [terrain.DNGN_SLIMY_WALL] = true,
    [terrain.DNGN_GRANITE_STATUE] = true,
    [terrain.DNGN_ORCISH_IDOL] = true,
    [terrain.DNGN_TREE] = true,
    [terrain.DNGN_PETRIFIED_TREE] = true,
    [terrain.DNGN_DEMONIC_TREE] = true,
}

-- Source sanitize_feature(strict=true) strips destinations from a
-- borrowed floor. This explicit list is safer than guessing from an
-- arbitrary modded feature name.
function borrowed.sanitize(feature)
    if substituted[feature] then
        return substituted[feature]
    end

    if feature == terrain.DNGN_STONE_STAIRS_UP_I or
        feature == terrain.DNGN_STONE_STAIRS_DOWN_I or
        feature == terrain.DNGN_SEALED_STAIRS_UP or
        feature == terrain.DNGN_SEALED_STAIRS_DOWN or
        feature == terrain.DNGN_RANDOM_ALTAR then
        return terrain.DNGN_FLOOR
    end

    if gates[feature] or feature == terrain.DNGN_TRANSPORTER or
        feature == terrain.DNGN_TRANSPORTER_LANDING then
        return terrain.DNGN_STONE_ARCH
    end

    return feature
end

-- Count the original neighboring walls, not already eroded cells. This
-- mirrors source LevelLayout's consultation of the borrowed live grid.
local function neighbor_walls(rows, x, y)
    local count = 0

    for offset_y = -1, 1 do
        for offset_x = -1, 1 do
            if offset_x ~= 0 or offset_y ~= 0 then
                local row = rows[y + offset_y]
                local feature = row and row[x + offset_x]

                if solid[feature] then
                    count = count + 1
                end
            end
        end
    end

    return count
end

-- Sanitize and erode a snapshot once when the visit begins. The saved
-- result, including unseen holes, guarantees restore never reselects or
-- re-erodes a floor after the ordinary level has changed.
function borrowed.prepare(ctx, rows)
    local height = #rows
    local width = #rows[1]
    local prepared = {}

    for y = 1, height do
        local row = {}

        for x = 1, width do
            local feature = borrowed.sanitize(rows[y][x])

            if x == 1 or y == 1 or x == width or y == height then
                feature = terrain.DNGN_UNSEEN
            else
                local walls = neighbor_walls(rows, x, y)

                if walls == 8 then
                    feature = terrain.DNGN_UNSEEN
                elseif walls >= 5 then
                    local parity = ctx:hash3_quotient_mod(
                        x - 1, y - 1, 5, 1, 2)
                    local divisor = parity == 0 and 11 or 12
                    local roll = ctx:hash3_quotient_mod(
                        x - 1, y - 1, 5, 2, divisor)

                    if roll == 0 then
                        feature = terrain.DNGN_UNSEEN
                    end
                elseif walls <= 1 then
                    local roll = ctx:hash3_quotient_mod(
                        x - 1, y - 1, 5, 1, 14)

                    if roll == 0 then
                        feature = terrain.DNGN_UNSEEN
                    end
                end
            end

            row[x] = feature
        end

        prepared[y] = row
    end

    return prepared
end

-- Source LevelLayout clips the world coordinate to the borrowed grid.
-- Its nil/UNSEEN cells must use rivers rather than reveal a dead edge.
function borrowed.sample(ctx, state, x, y, depth, fallback)
    local rows = state.borrowed_layout
    local height = #rows
    local width = #rows[1]
    local clipped_x = math.max(0, math.min(width - 1, x))
    local clipped_y = math.max(0, math.min(height - 1, y))
    local feature = rows[clipped_y + 1][clipped_x + 1]

    if feature == nil or feature == terrain.DNGN_UNSEEN then
        return fallback(ctx, state, x, y, depth)
    end

    return borrowed.sanitize(feature), depth + constants.STATIC_CHANGE
end

return borrowed
