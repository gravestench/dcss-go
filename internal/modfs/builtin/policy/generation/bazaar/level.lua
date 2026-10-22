-- Theory of operation: a Bazaar visit draws one effective source map by
-- weight, places that map as the entire floor, and projects its keyed shops
-- and exit through the ordinary DES terrain owner. The selected map ID is
-- saved with the level; revisiting must never draw another market.
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

-- All positive-weight Bazaar maps join the pool by stable ID. Reading the
-- effective catalog lets a mod add one map without changing this selector.
function level.candidates(player)
    vaults.load()

    local context = {
        branch_id = branches.BRANCH_BAZAAR,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 18,
        player = player,
    }
    local maps = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == "bazaar" and
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

-- Consume one bounded draw after summing source weights. File path order
-- cannot alter the draw, including when a mod overlays only one map.
local function choose(builder, player)
    local maps = level.candidates(player)
    local total = 0

    for _, map in ipairs(maps) do
        total = total + map.weight
    end

    if total == 0 then
        error("Bazaar has no eligible layout")
    end

    local draw = builder:roll(total)

    for _, map in ipairs(maps) do
        if draw < map.weight then
            return vaults.get(map.id)
        end

        draw = draw - map.weight
    end

    error("Bazaar layout draw exceeded the catalog")
end

-- Generate an uninstalled level record. The portal staging kernel owns
-- population and rollback; this policy owns only source map decisions.
function level.generate(ctx, input)
    local player = {
        branch_id = branches.BRANCH_BAZAAR,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 18,
        species_id = input.species_id,
        name = input.player_name,
    }
    local builder = grid.new(ctx)
    local definition = choose(builder, player)
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
            id = levels.id(branches.BRANCH_BAZAAR, 1),
            branch_id = branches.BRANCH_BAZAAR,
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
