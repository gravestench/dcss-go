-- Theory of operation: a branch can own full-sized, explicitly oriented
-- source vaults as well as small minivaults. Select those maps from the
-- effective DES family before small extras fill the remaining floor.
local catalog = require("policy.generation.vaults.catalog")
local categories = require("constants.catalog")
local eligibility = require("policy.generation.vaults.eligibility")
local weights = require("policy.generation.vaults.weight")

local regular = {}

-- A branch may reserve tagged definitions for a later dedicated role.
-- The Abyss, for example, draws rune and exit maps at different times
-- from its ordinary furniture rather than letting them fill a room slot.
local function allowed_tags(definition, context)
    for _, tag in ipairs(context.excluded_tags or {}) do
        if definition.tags[tag] then
            return false
        end
    end

    return true
end

-- A family directory is the mod extension point. DEPTH and source weight
-- still decide each map's eligibility; explicit ORIENT keeps a map out of
-- the separate minivault draw.
function regular.candidates(context)
    local candidates = {}

    if not context.branch_vault_family then
        return candidates
    end

    catalog.load()

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)
        local weight = weights.for_branch(definition,
            context.branch_id, context.depth,
            context.branch_bottom, context.absolute_depth)

        local family = definition.family == context.branch_vault_family or
            definition.family == context.shared_vault_family

        if family and
            allowed_tags(definition, context) and
            (not context.regular_extra_only or definition.tags.extra) and
            definition.orientation ~= "encompass" and
            not definition.tags.minivault and
            #definition.depths > 0 and #definition.chances == 0 and
            weight > 0 and eligibility.depth(definition, context) then
            candidates[#candidates + 1] = {
                definition = definition,
                weight = weight,
            }
        end
    end

    table.sort(candidates, function(left, right)
        return left.definition.id < right.definition.id
    end)

    return candidates
end

-- Draw once from the remaining weighted pool. Failed protected-stair fits
-- are removed before retry, while the layout RNG remains deterministic.
local function draw(random, candidates)
    local total = 0

    for _, candidate in ipairs(candidates) do
        total = total + candidate.weight
    end

    local pick = random:roll(total)

    for index, candidate in ipairs(candidates) do
        if pick < candidate.weight then
            table.remove(candidates, index)

            return candidate.definition
        end

        pick = pick - candidate.weight
    end

    error("regular vault weighted draw exceeded its candidates")
end

-- Keep only a successful map in history. The shared fitter restores a
-- rejected map's terrain, so another effective file can still fit.
function regular.place(ctx, builder, context, placed, fit)
    local candidates = regular.candidates(context)

    while #candidates > 0 do
        local selected = draw(builder, candidates)

        -- A source dummy participates in the same weighted draw but means
        -- "place no ordinary vault" when chosen. Retrying would defeat its
        -- purpose of lowering Zot:5 map density.
        if selected.tags.dummy then
            return nil
        end

        local vault = catalog.get(selected.id)
        local map = fit(ctx, builder, vault, context)

        if map then
            placed[#placed + 1] = map
            context.used:add_map(vault, map)

            return vault.id
        end
    end

    return nil
end

return regular
