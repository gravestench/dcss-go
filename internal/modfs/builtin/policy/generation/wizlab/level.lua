-- Theory of operation: every effective top-level Wizard Lab map can be
-- one complete temporary floor. The selector sorts stable vault IDs,
-- then draws by source weight. A requested ID is for verification or
-- authored mod gates; ordinary play makes one saved layout draw.
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
local wizlab = require("constants.wizlab")

local level = {}

-- The first authored exit is the landing, not an arbitrary free floor.
-- Other exits remain live and use the same saved outside return address.
local function arrival_exit(cells)
    for y, row in ipairs(cells) do
        for x, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_WIZLAB then
                return {
                    x = x - 1,
                    y = y - 1,
                }
            end
        end
    end

    error("Wizard Lab layout has no live return exit")
end

-- The effective VFS can add or replace individual lab maps. Never rely
-- on file enumeration order for the same seed's weighted selection.
function level.candidates(player)
    vaults.load()

    local context = {
        branch_id = branches.BRANCH_WIZLAB,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 24,
        player = player,
    }
    local maps = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == wizlab.DESTINATION_FAMILY and
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

-- Reject an unavailable requested layout before any population or gate
-- mutation. Normal selection consumes one draw from the staged builder.
local function choose(builder, player, requested_id)
    local maps = level.candidates(player)
    local total = 0

    if requested_id then
        for _, map in ipairs(maps) do
            if map.id == requested_id then
                return vaults.get(map.id)
            end
        end

        error("requested Wizard Lab layout is not eligible")
    end

    for _, map in ipairs(maps) do
        total = total + map.weight
    end

    if total == 0 then
        error("Wizard Lab has no eligible layout")
    end

    local draw = builder:roll(total)

    for _, map in ipairs(maps) do
        if draw < map.weight then
            return vaults.get(map.id)
        end

        draw = draw - map.weight
    end

    error("Wizard Lab layout draw exceeded the catalog")
end

-- Return an uninstalled floor to the generic staged portal transaction.
-- Its cells, records, actors, and RNG state commit together after travel.
function level.generate(ctx, input)
    local player = {
        branch_id = branches.BRANCH_WIZLAB,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 24,
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
            id = levels.id(branches.BRANCH_WIZLAB, 1),
            branch_id = branches.BRANCH_WIZLAB,
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
