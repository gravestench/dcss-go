-- Theory of operation: one accepted drain draws one effective Sewer map by
-- source weight and installs it as a single whole-floor level. Sorting the
-- candidates by stable ID keeps a mod path rename from changing a seed.
-- The saved vault ID records the one-time choice; a revisit never rerolls.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local eligibility = require("policy.generation.vaults.eligibility")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local levels = require("policy.generation.branch_levels")
local nearest = require("policy.generation.nearest")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")
local weights = require("policy.generation.vaults.weight")

local level = {}

-- Only source Sewer maps join this pool; Dungeon entrance maps have their
-- own tag selector and must not become a destination by accident.
function level.candidates(player)
    vaults.load()

    local context = {
        branch_id = branches.BRANCH_SEWER,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 4,
        player = player,
    }
    local maps = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == "sewer" and
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

-- Ordinary entry consumes one bounded map draw. An explicitly requested
-- eligible layout supports authored mod portals and focused full-corpus
-- verification without changing the default weighted selection.
local function choose(builder, player, requested_id)
    local maps = level.candidates(player)
    local total = 0

    -- A mod may request one eligible layout for an authored portal or
    -- quest. Ordinary drains omit this and retain the source weight draw.
    if requested_id then
        for _, map in ipairs(maps) do
            if map.id == requested_id then
                return vaults.get(map.id)
            end
        end

        error("requested Sewer layout is not eligible")
    end

    for _, map in ipairs(maps) do
        total = total + map.weight
    end

    if total == 0 then
        error("Sewer has no eligible layout")
    end

    local draw = builder:roll(total)

    for _, map in ipairs(maps) do
        if draw < map.weight then
            return vaults.get(map.id)
        end

        draw = draw - map.weight
    end

    error("Sewer layout draw exceeded the catalog")
end

-- Return an uninstalled level record to the generic portal transaction.
-- Population and rollback are engine services shared with Bazaar.
function level.generate(ctx, input)
    local player = {
        branch_id = branches.BRANCH_SEWER,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 4,
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
    local entry = nearest.open_feature(cells, placed.entry,
        terrain.DNGN_FLOOR)
    local ids = { placed.id }

    for _, id in ipairs(placed.vault_ids or {}) do
        ids[#ids + 1] = id
    end

    return {
        level = {
            id = levels.id(branches.BRANCH_SEWER, 1),
            branch_id = branches.BRANCH_SEWER,
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
