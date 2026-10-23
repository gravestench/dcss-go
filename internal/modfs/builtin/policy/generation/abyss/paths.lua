-- Theory of operation: source Abyss terrain receives sparse exits and
-- downward stairs after the sampler and authored furniture have painted
-- their cells. Only newly generated, unprotected cells can receive these
-- features; a shifted vault and the player's preserved neighborhood keep
-- their existing terrain.
local abyss = require("constants.abyss")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local branches = require("ids.branches")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.abyss.vaults")
local runes = require("policy.character.runes")
local items = require("ids.items")

local paths = {}

local solid = {
    [terrain.DNGN_ROCK_WALL] = true,
    [terrain.DNGN_STONE_WALL] = true,
    [terrain.DNGN_PERMAROCK_WALL] = true,
    [terrain.DNGN_METAL_WALL] = true,
    [terrain.DNGN_CRYSTAL_WALL] = true,
    [terrain.DNGN_CLEAR_ROCK_WALL] = true,
    [terrain.DNGN_CLEAR_STONE_WALL] = true,
    [terrain.DNGN_CLEAR_PERMAROCK_WALL] = true,
    [terrain.DNGN_TREE] = true,
    [terrain.DNGN_GRANITE_STATUE] = true,
}

-- Source feature placement avoids solid bubbles with more than six
-- neighboring walls. This allows an exit in a narrow passage, while
-- refusing a feature sealed into an eight-wall pocket.
local function open_neighbors(cells, x, y)
    local walls = 0

    for offset_y = -1, 1 do
        for offset_x = -1, 1 do
            if offset_x ~= 0 or offset_y ~= 0 then
                if solid[cells[y + offset_y + 1][x + offset_x + 1]] then
                    walls = walls + 1
                end
            end
        end
    end

    return walls <= 6
end

-- An unplaced source roll carries forward to the next eligible cell.
-- The branch's authored bottom depth, rather than a second hard-coded
-- seven, controls whether a downward stair can still be generated.
-- The source treats possession of the Abyssal rune as maximum effective
-- depth for ordinary exit rolls. This makes escape much more likely even
-- if the rune was found at an earlier branch depth.
function paths.exit_chance(ctx, state)
    local depth = state.branch_depth - 2

    if runes.has(ctx, ctx:player(), items.RUNE_ABYSSAL) then
        depth = abyss.EXIT_DEPTH_CAP
    end

    local effective_depth = math.min(depth, abyss.EXIT_DEPTH_CAP)

    return abyss.EXIT_BASE_CHANCE -
        abyss.EXIT_DEPTH_STEP * effective_depth
end

-- Walk each unprotected cell and consume the source's carried feature
-- wishes in coordinate order. The saved rune set shapes the exit roll.
function paths.place(ctx, cells, state, protected)
    local bottom = catalog.get(categories.BRANCHES,
        branches.BRANCH_ABYSS).depth
    local exit_chance = paths.exit_chance(ctx, state)
    local exits_wanted = 0
    local stairs_wanted = 0
    local exits_placed = 0
    local stairs_placed = 0
    local map_records = {}
    local map_ids = {}
    local use_exit_map = true

    for y = 1, abyss.HEIGHT - 2 do
        for x = 1, abyss.WIDTH - 2 do
            if ctx:random("abyss-features", exit_chance) == 0 then
                exits_wanted = exits_wanted + 1
            end

            if state.branch_depth < bottom and
                ctx:random("abyss-features", abyss.STAIR_CHANCE) == 0 then
                stairs_wanted = stairs_wanted + 1
            end

            local key = x .. ":" .. y

            if not protected[key] and open_neighbors(cells, x, y) then
                if exits_wanted > 0 then
                    local placed

                    if use_exit_map then
                        placed = vaults.place_tagged(ctx, cells,
                            state, protected, "abyss_exit")
                        use_exit_map = false
                    end

                    if placed then
                        cells = placed.cells
                        map_ids[#map_ids + 1] = placed.id

                        for _, point in ipairs(placed.occupied) do
                            protected[point.x .. ":" .. point.y] = true
                        end

                        for _, record in ipairs(placed.records) do
                            map_records[#map_records + 1] = record
                        end

                        for _, id in ipairs(placed.vault_ids or {}) do
                            if id ~= placed.id then
                                map_ids[#map_ids + 1] = id
                            end
                        end
                    else
                        cells[y + 1][x + 1] = terrain.DNGN_EXIT_ABYSS
                    end

                    exits_wanted = exits_wanted - 1
                    exits_placed = exits_placed + 1
                elseif stairs_wanted > 0 then
                    cells[y + 1][x + 1] = terrain.DNGN_ABYSSAL_STAIR
                    stairs_wanted = stairs_wanted - 1
                    stairs_placed = stairs_placed + 1
                end
            end
        end
    end

    return cells, map_records, map_ids, protected,
        exits_placed, stairs_placed
end

return paths
