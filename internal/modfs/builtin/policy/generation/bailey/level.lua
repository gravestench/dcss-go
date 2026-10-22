-- Theory of operation: Bailey's source controller owns no terrain. An
-- entrance stores its axe or polearm choice; this owner runs the mapless
-- controller with that theme, then stages its one selected child as the
-- complete temporary floor. The controller and child both enter history.
local bailey = require("constants.bailey")
local branches = require("ids.branches")
local categories = require("constants.catalog")
local controller = require("policy.generation.vaults.controller")
local directives = require("constants.vault_directives")
local eligibility = require("policy.generation.vaults.eligibility")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local hooks = require("policy.generation.vaults.hooks")
local levels = require("policy.generation.branch_levels")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local used = require("policy.generation.vaults.used")
local vaults = require("policy.generation.vaults.catalog")
local weights = require("policy.generation.vaults.weight")

local level = {}

-- A missing or forged theme must stop before a layout or RNG draw. The
-- source Wizmode fallback is not part of an ordinary saved game.
local function theme_tag(theme)
    if theme == bailey.AXE then
        return bailey.AXE_TAG
    end

    if theme == bailey.POLEARM then
        return bailey.POLEARM_TAG
    end

    error("Bailey generation requires a saved axe or polearm theme")
end

-- A modded child joins by its source tag and positive effective weight.
-- Stable ID order means adding files in another VFS layer cannot reorder
-- the built-in pool merely because the filesystem listed them differently.
function level.candidates(theme, player)
    local tag = theme_tag(theme)
    local context = {
        branch_id = branches.BRANCH_BAILEY,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 11,
        player = player,
    }
    local maps = {}

    vaults.load()

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == "bailey" and
            definition.tags[tag] and
            eligibility.tag(definition, context) then
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

-- The chosen return arch is the arrival anchor. Some source maps have
-- isolated plain floor before their first exit in row order, so an
-- arbitrary floor cell could strand a newly arrived character.
local function arrival_exit(cells)
    for y, row in ipairs(cells) do
        for x, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_BAILEY then
                return {
                    x = x - 1,
                    y = y - 1,
                }
            end
        end
    end

    error("Bailey layout has no live return exit")
end

-- The controller API invokes this normal fitter only for a tagged child.
-- Whole-level placement keeps the source encompass rows and typed records.
local function place_child(ctx, _, builder, vault, context)
    return placement.place(ctx, builder, vault, context.player, {
        whole_level = true,
    })
end

-- Return an uninstalled floor for the generic staged portal transaction.
-- Explicit layout requests are for full-corpus validation and authored
-- mod gates; ordinary entry draws one positive-weight matching child.
function level.generate(ctx, input)
    local theme = input.theme
    local maps = level.candidates(theme, {
        species_id = input.species_id,
    })

    if #maps == 0 then
        error("Bailey has no eligible layout for saved theme " .. theme)
    end

    local excluded = {}

    if input.layout_id then
        local found = false

        for _, map in ipairs(maps) do
            if map.id == input.layout_id then
                found = true
            else
                excluded[map.id] = true
            end
        end

        if not found then
            error("requested Bailey layout is not eligible for saved theme")
        end
    end

    local player = {
        branch_id = branches.BRANCH_BAILEY,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 11,
        species_id = input.species_id,
        name = input.player_name,
    }
    local context = {
        branch_id = branches.BRANCH_BAILEY,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 11,
        player = player,
        bailey_theme = theme,
        excluded = excluded,
        used = used.new({}),
    }
    local builder = grid.new(ctx)
    local placed = {}
    local dispatcher = vaults.get("bailey")

    context.used:add(dispatcher)

    local api = controller.new(builder, context, placed,
        function(_, child_builder, vault, child_context)
            return place_child(ctx, nil, child_builder, vault,
                child_context)
        end, dispatcher.id)
    local selected

    for _, operation in ipairs(dispatcher.operations) do
        if operation.kind == directives.HOOK_POST_PLACE then
            selected = hooks.run(dispatcher, operation.argument, api)
        end
    end

    if #placed ~= 1 or selected ~= placed[1].id then
        error("Bailey dispatcher did not place exactly one themed child")
    end

    local map = placed[1]
    local cells = features.decode_source_rows(builder:rows())
    local records = features.apply_vault_terrain(cells,
        map.records, ctx, 1)
    local entry = arrival_exit(cells)

    return {
        level = {
            id = levels.id(branches.BRANCH_BAILEY, 1),
            branch_id = branches.BRANCH_BAILEY,
            local_depth = 1,
            cells = cells,
            stairs = {},
            entry_x = entry.x,
            entry_y = entry.y,
            initial_monsters = 0,
            vault_id = selected,
            vault_ids = context.used:ids(),
            vault_records = records,
        },
    }
end

return level
