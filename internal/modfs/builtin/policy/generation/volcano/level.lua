-- Theory of operation: a Volcano visit is one authored, whole-floor DES
-- map. The effective mod catalog supplies the weighted choice; a staging
-- transaction installs the finished grid and its typed source records.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local eligibility = require("policy.generation.vaults.eligibility")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local levels = require("policy.generation.branch_levels")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local transporters = require("policy.generation.transporters")
local vaults = require("policy.generation.vaults.catalog")
local weights = require("policy.generation.vaults.weight")
local volcano = require("constants.volcano")

local level = {}

-- Tagged children belong to SUBVAULT operations, not the whole-floor draw.
-- Sort IDs so adding or renaming a mod file cannot disturb seeded choices.
function level.candidates(player)
    vaults.load()

    local context = {
        branch_id = branches.BRANCH_VOLCANO,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 14,
        player = player,
    }
    local maps = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)
        local tags = definition.tags or {}

        if definition.family == volcano.DESTINATION_FAMILY and
            not tags[volcano.GROTTO_HELPER_TAG] and
            not tags[volcano.LAKE_HELPER_TAG] and
            not tags[volcano.TOMB_HELPER_TAG] and
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

-- The first authored return arch is the arrival point. Multiple arches
-- remain in the level and all return to the same saved outside coordinate.
local function arrival_exit(cells)
    for y, row in ipairs(cells) do
        for x, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_VOLCANO then
                return {
                    x = x - 1,
                    y = y - 1,
                }
            end
        end
    end

    error("Volcano layout has no live return exit")
end

-- A requested map must belong to the positive effective pool; normal
-- travel makes exactly one weighted draw from that same pool.
local function choose(builder, player, requested_id)
    local maps = level.candidates(player)
    local total = 0

    if requested_id then
        for _, map in ipairs(maps) do
            if map.id == requested_id then
                return vaults.get(map.id)
            end
        end

        error("requested Volcano layout is not eligible")
    end

    for _, map in ipairs(maps) do
        total = total + map.weight
    end

    if total == 0 then
        error("Volcano has no eligible layout")
    end

    local draw = builder:roll(total)

    for _, map in ipairs(maps) do
        if draw < map.weight then
            return vaults.get(map.id)
        end

        draw = draw - map.weight
    end

    error("Volcano layout draw exceeded the catalog")
end

-- Generate in isolation. The generic staged-floor owner later commits
-- population and player movement together or rolls all changes back.
function level.generate(ctx, input)
    local player = {
        branch_id = branches.BRANCH_VOLCANO,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 14,
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

    local result = {
        level = {
            id = levels.id(branches.BRANCH_VOLCANO, 1),
            branch_id = branches.BRANCH_VOLCANO,
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
