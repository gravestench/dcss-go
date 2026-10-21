-- Source non-minivault maps are considered before procedural layouts. A
-- Depths encompassing map owns its entire floor, so it cannot be fitted by
-- the secondary vault pass after stairs and branch gates already exist.
local categories = require("constants.catalog")
local depth = require("policy.generation.vaults.depth")
local vaults = require("policy.generation.vaults.catalog")
local used = require("policy.generation.vaults.used")
local weights = require("policy.generation.vaults.weight")
local authored = require("policy.generation.layouts.authored")
local stairs = require("policy.generation.layouts.stairs")
local tags = require("constants.vault_tags")

local encompass = {}

-- Match one source selector stage: an explicit PLACE pool wins over the
-- ordinary DEPTH pool. A prior `uniq_d_encompass` ID removes its whole
-- family, allowing the ordinary layout fallback on later floors.
function encompass.candidates(context)
    vaults.load()

    local history = used.new(context.prior_vault_ids)
    local placed = {}
    local ordinary = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == context.family and
            definition.orientation == "encompass" and
            definition.tags[tags.UNIQ_DEPTHS_ENCOMPASS] and
            history:allows(definition) then
            local weight = weights.for_branch(definition,
                context.branch_id, context.depth,
                context.branch_bottom, context.absolute_depth)

            if weight > 0 and #definition.places > 0 and
                depth.eligible({ depths = definition.places },
                    context.branch_id, context.depth,
                    context.branch_bottom, context.absolute_depth) then
                placed[#placed + 1] = {
                    definition = definition,
                    weight = weight,
                }
            elseif weight > 0 and #definition.places == 0 and
                depth.eligible(definition, context.branch_id,
                    context.depth, context.branch_bottom,
                    context.absolute_depth) then
                ordinary[#ordinary + 1] = {
                    definition = definition,
                    weight = weight,
                }
            end
        end
    end

    local candidates = #placed > 0 and placed or ordinary

    table.sort(candidates, function(left, right)
        return left.definition.id < right.definition.id
    end)

    return candidates
end

-- Draw from stable IDs so filesystem discovery and same-path mod overlays
-- cannot change the seed simply by renaming files.
function encompass.choose(random, candidates)
    local total = 0

    for _, candidate in ipairs(candidates) do
        total = total + candidate.weight
    end

    if total == 0 then
        return nil
    end

    local draw = random:roll(total)

    for _, candidate in ipairs(candidates) do
        if draw < candidate.weight then
            return candidate.definition
        end

        draw = draw - candidate.weight
    end

    error("encompass weight draw exceeded the source candidate pool")
end

-- Paint the selected DES map on a fresh grid, then complete only missing
-- ordinary stairs. The source map and its tagged child records enter the
-- level before any other vault or provisional procedural layout exists.
function encompass.execute(ctx, definition, context, profile)
    local api = {
        ctx = ctx,
        definition = vaults.get(definition.id),
        branch_id = context.branch_id,
        depth = context.depth,
        branch_bottom = context.branch_bottom,
        absolute_depth = context.absolute_depth,
        prior_vault_ids = context.prior_vault_ids,
        branch_entries = context.branch_entries,
    }
    local result = authored.execute(api)

    result.stairs = stairs.complete_encompass(result.builder, profile)
    -- The first completed pair belongs to the main connected chamber.
    -- Travel pairing must retain that landing even after sorting exits.
    result.prefer_main_entry = true
    result.rows = result.builder:rows()
    result.id = definition.id
    result.primary_id = definition.id
    result.primary_placement = result.placement

    table.insert(result.vault_ids, 1, definition.id)

    return result
end

return encompass
