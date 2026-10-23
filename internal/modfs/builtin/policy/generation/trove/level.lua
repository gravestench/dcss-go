-- Theory of operation: one source Treasure Trove DES definition owns one
-- temporary reward floor. The effective catalog provides a stable weighted
-- choice; placement records every authored effect; generic staged travel
-- installs the populated grid only after it is valid.
-- Example: a sparse mod may add a positive-weight `vaults/trove/*.des`
-- file and have it participate without changing this policy.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local connect = require("policy.generation.vaults.connect")
local eligibility = require("policy.generation.vaults.eligibility")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local levels = require("policy.generation.branch_levels")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local transporters = require("policy.generation.transporters")
local trove = require("constants.trove")
local vaults = require("policy.generation.vaults.catalog")
local weights = require("policy.generation.vaults.weight")

local level = {}

-- Sort positive effective source maps by NAME so the weighted draw is
-- independent of file discovery and sparse mod directory order.
function level.candidates(player)
    vaults.load()

    local context = {
        branch_id = branches.BRANCH_TROVE,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 18,
        player = player,
    }
    local maps = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == trove.DESTINATION_FAMILY and
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

-- Keep the source `<` cells as Trove exit arches even on the one map that
-- relies on the branch default instead of calling shared.setup.
local function return_arches(cells)
    local first

    for y, row in ipairs(cells) do
        for x, feature in ipairs(row) do
            if feature == terrain.DNGN_STONE_STAIRS_UP_I or
                feature == terrain.DNGN_EXIT_TROVE then
                row[x] = terrain.DNGN_EXIT_TROVE
                first = first or {
                    x = x - 1,
                    y = y - 1,
                }
            end
        end
    end

    if not first then
        error("Treasure Trove layout has no return arch")
    end

    return first
end

-- Draw among remaining maps after a source veto. The map's weight stays
-- unchanged; only an ineligible candidate leaves this one generation try.
local function choose(builder, maps, requested_id)
    local total = 0

    if requested_id then
        for _, map in ipairs(maps) do
            if map.id == requested_id then
                return vaults.get(map.id)
            end
        end

        error("requested Treasure Trove layout is not eligible")
    end

    for _, map in ipairs(maps) do
        total = total + map.weight
    end

    if total == 0 then
        error("Treasure Trove has no eligible layout")
    end

    local draw = builder:roll(total)

    for _, map in ipairs(maps) do
        if draw < map.weight then
            return vaults.get(map.id)
        end

        draw = draw - map.weight
    end

    error("Treasure Trove draw exceeded the catalog")
end

-- A vetoed whole-floor map is retried with another source definition.
-- Other placement errors remain errors so a broken mod is reported.
local function place_allowed(ctx, player, requested_id)
    local maps = level.candidates(player)

    while #maps > 0 do
        local builder = grid.new(ctx)
        local definition = choose(builder, maps, requested_id)
        local placed = placement.place(ctx, builder, definition, player, {
            whole_level = true,
        })
        local accepted, reason = pcall(connect.check_vetoes,
            ctx, builder, placed)

        if accepted then
            return builder, placed
        end

        if requested_id or not tostring(reason):find(
            "veto .+ rejected placement") then
            error(reason)
        end

        for index, map in ipairs(maps) do
            if map.id == definition.id then
                table.remove(maps, index)
                break
            end
        end
    end

    error("Treasure Trove has no eligible layout after vetoes")
end

-- Stage the source map, its feature projection, and all typed records.
-- Population and travel later commit together in the generic transaction.
function level.generate(ctx, input)
    local player = {
        branch_id = branches.BRANCH_TROVE,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 18,
        species_id = input.species_id,
        name = input.player_name,
        started = true,
    }
    local builder, placed = place_allowed(ctx, player, input.layout_id)
    local cells = features.decode_source_rows(builder:rows())
    local records = features.apply_vault_terrain(cells,
        placed.records, ctx, 1)
    local entry = return_arches(cells)
    local ids = { placed.id }

    for _, id in ipairs(placed.vault_ids or {}) do
        ids[#ids + 1] = id
    end

    local result = {
        level = {
            id = levels.id(branches.BRANCH_TROVE, 1),
            branch_id = branches.BRANCH_TROVE,
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

    transporters.resolve(result.level)

    return result
end

return level
