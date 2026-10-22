-- Theory of operation: an accepted gate selects one effective source map
-- by its authored weight and installs it as the whole temporary floor.
-- Sorting by stable vault ID keeps file enumeration and sparse overlays
-- from changing a seed. The chosen ID is saved; no revisit redraws it.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local eligibility = require("policy.generation.vaults.eligibility")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local levels = require("policy.generation.branch_levels")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")
local weights = require("policy.generation.vaults.weight")

local level = {}

-- The return portal is the connected arrival anchor. Some source maps
-- have isolated one-cell rooms before their exit in row order; choosing
-- their first plain floor can strand a player behind a closed door.
local function arrival_exit(cells)
    for y, row in ipairs(cells) do
        for x, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_OSSUARY then
                return {
                    x = x - 1,
                    y = y - 1,
                }
            end
        end
    end

    error("Ossuary layout has no live return exit")
end

-- Destination maps belong to Ossuary, while D:4–8 entrance maps have a
-- separate family and can never join this draw by accident.
function level.candidates(player)
    vaults.load()

    local context = {
        branch_id = branches.BRANCH_OSSUARY,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 6,
        player = player,
    }
    local maps = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == "ossuary" and
            eligibility.depth(definition, context) then
            local weight = weights.for_branch(definition,
                context.branch_id, context.depth,
                context.branch_bottom, context.absolute_depth)

            if weight > 0 then
                maps[#maps + 1] = {
                    id = id,
                    weight = weight,
                }
            end
        end
    end

    table.sort(maps, function(left, right)
        return left.id < right.id
    end)

    return maps
end

-- An explicitly requested eligible map supports authored mod gates and
-- full-corpus verification. Normal play makes one weighted source draw.
local function choose(builder, player, requested_id)
    local maps = level.candidates(player)
    local total = 0

    if requested_id then
        for _, map in ipairs(maps) do
            if map.id == requested_id then
                return vaults.get(map.id)
            end
        end

        error("requested Ossuary layout is not eligible")
    end

    for _, map in ipairs(maps) do
        total = total + map.weight
    end

    if total == 0 then
        error("Ossuary has no eligible layout")
    end

    local draw = builder:roll(total)

    for _, map in ipairs(maps) do
        if draw < map.weight then
            return vaults.get(map.id)
        end

        draw = draw - map.weight
    end

    error("Ossuary layout draw exceeded the catalog")
end

-- Return an uninstalled floor to the generic staged portal transaction.
-- The engine commits or rolls back population and dynamic entities.
function level.generate(ctx, input)
    local player = {
        branch_id = branches.BRANCH_OSSUARY,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 6,
        species_id = input.species_id,
        name = input.player_name,
    }
    local builder = grid.new(ctx)
    local definition = choose(builder, player, input.layout_id)
    local placed = placement.place(ctx, builder, definition, player, {
        whole_level = true,
    })
    local cells = features.decode_source_rows(builder:rows())
    local records = features.apply_vault_terrain(cells,
        placed.records, ctx, 1)
    local entry = arrival_exit(cells)
    local ids = { placed.id }

    for _, id in ipairs(placed.vault_ids or {}) do
        ids[#ids + 1] = id
    end

    return {
        level = {
            id = levels.id(branches.BRANCH_OSSUARY, 1),
            branch_id = branches.BRANCH_OSSUARY,
            local_depth = 1,
            cells = cells,
            stairs = {},
            entry_x = entry.x,
            entry_y = entry.y,
            initial_monsters = 0,
            vault_id = placed.id,
            vault_ids = ids,
            vault_records = records,
        },
    }
end

return level
