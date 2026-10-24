-- Theory of operation: player corruption samples every interior grid cell
-- against its nearest nexus, then permanently replaces eligible terrain.
-- Portals, stairs, sea, and the player cell keep their travel invariants;
-- creatures and items are pushed before an impassable feature is installed.
local displacement = require("policy.combat.monster_corruption_displacement")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local corruption = {}
local proto = {
    { feature = terrain.DNGN_FLOOR, weight = 3000 },
    { feature = terrain.DNGN_ROCK_WALL, weight = 600 },
    { feature = terrain.DNGN_STONE_WALL, weight = 300 },
    { feature = terrain.DNGN_METAL_WALL, weight = 100 },
    { feature = terrain.DNGN_CLOSED_DOOR, weight = 1 },
}

-- The proto-Abyss distribution is shared by source player and monster
-- corruption. Keep its weighted draw here so a mod can change it once.
local function proto_feature(ctx)
    local draw = ctx:random(streams.LUGONU_CORRUPTION, 4001)

    for _, entry in ipairs(proto) do
        draw = draw - entry.weight

        if draw < 0 then
            return entry.feature
        end
    end

    error("invalid corruption feature draw")
end

-- Source cannot replace transport features. Restrict replacement to
-- ordinary terrain and altars, which also preserves mod-added portals.
local function eligible(feature)
    if feature == terrain.DNGN_FLOOR or
        feature == terrain.DNGN_TREE or
        feature == terrain.DNGN_DEMONIC_TREE or
        feature == terrain.DNGN_CLOSED_DOOR or
        feature == terrain.DNGN_ROCK_WALL or
        feature == terrain.DNGN_CLEAR_ROCK_WALL or
        feature == terrain.DNGN_STONE_WALL or
        feature == terrain.DNGN_CLEAR_STONE_WALL or
        feature == terrain.DNGN_METAL_WALL or
        feature == terrain.DNGN_CRYSTAL_WALL then
        return true
    end

    return feature and feature:find("^DNGN_ALTAR_") ~= nil
end

-- Resistant walls retain source one-in-four and one-in-three odds.
-- Rock is the exception: two of three rolls admit corruption.
local function admits(ctx, feature)
    local stream = streams.LUGONU_CORRUPTION

    if feature == terrain.DNGN_METAL_WALL or
        feature == terrain.DNGN_CRYSTAL_WALL then
        return ctx:random(stream, 4) == 0
    end

    if feature == terrain.DNGN_STONE_WALL or
        feature == terrain.DNGN_CLEAR_STONE_WALL then
        return ctx:random(stream, 3) == 0
    end

    if feature == terrain.DNGN_ROCK_WALL or
        feature == terrain.DNGN_CLEAR_ROCK_WALL then
        return ctx:random(stream, 3) ~= 0
    end

    return true
end

-- Source's crowded-square rule avoids sealing a small open pocket with
-- a newly solid feature. Count all eight traversable neighbours.
local function crowded(ctx, level_id, x, y)
    local count = 0

    for dy = -1, 1 do
        for dx = -1, 1 do
            if (dx ~= 0 or dy ~= 0) and
                ctx:walkable(level_id, x + dx, y + dy) then
                count = count + 1
            end
        end
    end

    return count <= 4
end

-- Opening a wall with no traversable neighbour creates an isolated
-- compartment. Source rejects that change before touching the grid.
local function sealed(ctx, level_id, x, y)
    for dy = -1, 1 do
        for dx = -1, 1 do
            if (dx ~= 0 or dy ~= 0) and
                ctx:walkable(level_id, x + dx, y + dy) then
                return false
            end
        end
    end

    return true
end

-- Replacing a traversable cell with a wall can only proceed if its
-- occupants can be moved by the shared monster-corruption helper.
local function replace(ctx, level_id, x, y, original)
    local feature

    if original:find("^DNGN_ALTAR_") then
        feature = ctx:random(streams.LUGONU_CORRUPTION, 3) == 0 and
            terrain.DNGN_FLOOR or terrain.DNGN_ALTAR_LUGONU
    else
        feature = proto_feature(ctx)
    end

    local was_open = ctx:walkable(level_id, x, y)
    local now_open = feature == terrain.DNGN_FLOOR or
        feature == terrain.DNGN_ALTAR_LUGONU

    if was_open and not now_open and
        ctx:random(streams.LUGONU_CORRUPTION, 2) == 0 then
        feature = terrain.DNGN_FLOOR
        now_open = true
    end

    if was_open and not now_open and crowded(ctx, level_id, x, y) then
        return
    end

    if not was_open and now_open and sealed(ctx, level_id, x, y) then
        return
    end

    if not now_open and not displacement.clear(ctx, level_id, x, y) then
        feature = terrain.DNGN_FLOOR
    end

    ctx:set_cell(level_id, x, y, feature)
end

-- Distance uses Chebyshev radius. The source curve is 100% near a seed,
-- 30% at radius seven and a small residual chance at radius eight.
local function chance(distance)
    if distance <= 2 then
        return 1000
    end

    return math.max(0, 1000 -
        (distance * distance - 4) * 700 / 45)
end

-- Permanent terrain is saved in the ordinary level grid. Nexus entities
-- determine this initial pass only; turns do not reroll terrain later.
function corruption.apply(ctx, level_id, player_x, player_y, seeds)
    local width, height = ctx:level_size(level_id)

    for y = 1, height - 2 do
        for x = 1, width - 2 do
            local nearest = width + height

            for _, seed in ipairs(seeds) do
                local distance = math.max(math.abs(seed.x - x),
                    math.abs(seed.y - y))

                nearest = math.min(nearest, distance)
            end

            local draw = ctx:random(streams.LUGONU_CORRUPTION, 1000)
            local feature = ctx:cell(level_id, x, y)
            local nexus_cell = false

            for _, seed in ipairs(seeds) do
                nexus_cell = nexus_cell or
                    seed.x == x and seed.y == y
            end

            -- Source shifts markers with the floor when replacing a
            -- nexus cell. Keep that floor in place until the grid owner
            -- can move arbitrary marker and feature pairs together.
            if not nexus_cell and
                (x ~= player_x or y ~= player_y) and
                eligible(feature) and draw < chance(nearest) and
                admits(ctx, feature) then
                replace(ctx, level_id, x, y, feature)
            elseif feature == terrain.DNGN_TREE and
                draw < math.max(10, 380 - 150 * nearest / 13) then
                -- ASCII has no source grid colour layer. Demonic trees
                -- retain the visible flavour portion of that effect.
                ctx:set_cell(level_id, x, y,
                    terrain.DNGN_DEMONIC_TREE)
            end
        end
    end
end

return corruption
