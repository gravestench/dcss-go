-- Xom samples the current floor rather than trusting a full map scan.
-- Magic-mapped cells count for divination, while teleportation asks whether
-- the player actually visited or saw them. This follows xom.cc's bounded
-- exploration estimate and consumes only the requested RNG stream.
local terrain = require("constants.terrain")
local streams = require("constants.rng_streams")

local exploration = {}

local adjacent = {
    { x = -1, y = -1 },
    { x = 0, y = -1 },
    { x = 1, y = -1 },
    { x = -1, y = 0 },
    { x = 1, y = 0 },
    { x = -1, y = 1 },
    { x = 0, y = 1 },
    { x = 1, y = 1 },
}

-- Doors interrupt walking but remain meaningful exploration targets.
-- Keep the source feature distinction here, not in the generic grid API.
local function closed_door(feature)
    return feature == terrain.DNGN_CLOSED_DOOR or
        feature == terrain.DNGN_CLOSED_CLEAR_DOOR or
        feature == terrain.DNGN_SEALED_DOOR or
        feature == terrain.DNGN_SEALED_CLEAR_DOOR
end

-- Do not count sealed rock buried in the wall mass. A bordering clear
-- feature or door makes an otherwise solid cell reachable by sight.
local function qualifying(ctx, level_id, x, y)
    local feature = ctx:cell(level_id, x, y)

    if not ctx:solid(level_id, x, y) or closed_door(feature) then
        return true
    end

    for _, offset in ipairs(adjacent) do
        local neighbor_x = x + offset.x
        local neighbor_y = y + offset.y
        local neighbor = ctx:cell(level_id, neighbor_x, neighbor_y)

        if neighbor and
            (not ctx:opaque(level_id, neighbor_x, neighbor_y) or
                closed_door(neighbor)) then
            return true
        end
    end

    return false
end

-- Avoid an RNG call for a one-cell dimension. The C++ random2(1) result
-- is always zero, so this keeps the same cell without consuming a draw.
local function coordinate(ctx, stream, bound)
    if bound <= 1 then
        return 0
    end

    return ctx:random(stream, bound)
end

-- Stop at 100 qualifying samples or 1000 attempts. A completely walled
-- floor is treated as fully explored, preventing pointless Xom divination.
function exploration.estimate(ctx, level_id, seen_only, stream)
    stream = stream or streams.RELIGION

    local width, height = ctx:level_size(level_id)

    if not width or not height or width < 1 or height < 1 then
        return 100
    end

    local seen = 0
    local total = 0
    local tries = 0

    repeat
        tries = tries + 1

        local x = coordinate(ctx, stream, width)
        local y = coordinate(ctx, stream, height)
        local known = ctx:seen(level_id, x, y)

        if not seen_only then
            known = known or ctx:remembered(level_id, x, y) ~= nil
        end

        if known then
            seen = seen + 1
            total = total + 1
        elseif qualifying(ctx, level_id, x, y) then
            total = total + 1
        end
    until total >= 100 or tries >= 1000

    if total == 0 then
        return 100
    end

    if total < 100 then
        return seen * math.floor(100 / total)
    end

    return seen
end

return exploration
