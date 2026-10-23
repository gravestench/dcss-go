-- Theory of operation: the effective DES catalog owns three complete
-- Desolation maps. This policy makes one stable, source-weighted draw,
-- lets the generic SUBVAULT operation populate each ruin slot, then
-- stages the resulting floor for the shared portal transaction. No
-- prebuilt copy of a map or hard-coded ruin list lives in Go.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local catalog = require("policy.catalog")
local desolation = require("constants.desolation")
local eligibility = require("policy.generation.vaults.eligibility")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local levels = require("policy.generation.branch_levels")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")
local weights = require("policy.generation.vaults.weight")

local level = {}

-- A source < is an exit arch after KFEAT, and the first one is the
-- visitor's arrival cell. The other arches remain usable for return.
local function arrival_exit(cells)
    for y, row in ipairs(cells) do
        for x, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_DESOLATION then
                return {
                    x = x - 1,
                    y = y - 1,
                }
            end
        end
    end

    error("Desolation layout has no live return exit")
end

-- A sparse mod may add another complete DES map. Source weights select
-- by ID order so file names and directory enumeration cannot alter seeds.
function level.candidates(player)
    vaults.load()
    local branch = catalog.get(categories.BRANCHES,
        branches.BRANCH_DESOLATION)

    local context = {
        branch_id = branches.BRANCH_DESOLATION,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = branch.absolute_depth,
        player = player,
    }
    local candidates = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == desolation.DESTINATION_FAMILY and
            eligibility.depth(definition, context) then
            local weight = weights.for_branch(definition,
                context.branch_id, context.depth,
                context.branch_bottom, context.absolute_depth)

            if weight > 0 then
                candidates[#candidates + 1] = {
                    id = id,
                    weight = weight,
                }
            end
        end
    end

    table.sort(candidates, function(left, right)
        return left.id < right.id
    end)

    return candidates
end

-- Tests and authored mod gates can request a particular map; normal
-- play uses one draw from the staged builder's RNG stream.
local function choose(builder, player, requested_id)
    local candidates = level.candidates(player)
    local total = 0

    for _, candidate in ipairs(candidates) do
        if requested_id and candidate.id == requested_id then
            return vaults.get(candidate.id)
        end

        total = total + candidate.weight
    end

    if requested_id then
        error("requested Desolation layout is not eligible")
    end

    if total == 0 then
        error("Desolation has no eligible layout")
    end

    local draw = builder:roll(total)

    for _, candidate in ipairs(candidates) do
        if draw < candidate.weight then
            return vaults.get(candidate.id)
        end

        draw = draw - candidate.weight
    end

    error("Desolation layout draw exceeded the catalog")
end

-- Population and travel see one uninstalled level. The generic staged
-- transaction commits its actors, fog markers, cells, and RNG together.
function level.generate(ctx, input)
    local branch = catalog.get(categories.BRANCHES,
        branches.BRANCH_DESOLATION)
    local player = {
        branch_id = branches.BRANCH_DESOLATION,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = branch.absolute_depth,
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
            id = levels.id(branches.BRANCH_DESOLATION, 1),
            branch_id = branches.BRANCH_DESOLATION,
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
