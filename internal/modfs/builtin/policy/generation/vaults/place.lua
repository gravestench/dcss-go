-- Source PLACE maps get one weighted attempt before the ordinary depth
-- minivault pool. Their explicit branch/floor rule is not a DEPTH rule.
local catalog = require("policy.generation.vaults.catalog")
local categories = require("constants.catalog")
local eligibility = require("policy.generation.vaults.eligibility")
local weights = require("policy.generation.vaults.weight")

local place = {}

-- Test fixtures may supply parsed DES records; the live path reads the
-- registered catalog. Sorting IDs prevents file discovery order from
-- changing seeded weighted decisions when a mod adds another map.
function place.candidates(context, definitions)
    local source = definitions or {}
    local candidates = {}

    if not definitions then
        for _, id in ipairs(register.ids(categories.VAULTS)) do
            source[#source + 1] = register.get(categories.VAULTS, id)
        end
    end

    for _, definition in ipairs(source) do
        local weight = weights.for_branch(definition, context.branch_id,
            context.depth, context.branch_bottom,
            context.absolute_depth)

        if weight > 0 and eligibility.place(definition, context) then
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

-- A selected source dummy ends the one PLACE attempt without geometry.
-- Empty pools spend no RNG draw; other pools use one cumulative draw.
function place.choose(random, candidates)
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
            return not candidate.definition.tags.dummy and
                candidate.definition or nil
        end

        draw = draw - candidate.weight
    end

    error("PLACE weight selection exceeded the catalog")
end

-- DCSS attempts exactly one PLACE minivault even when it is tagged
-- extra or its geometry fails. Record the ID only after a successful fit.
function place.place(ctx, builder, context, placed, fit, place_controller)
    local selected = place.choose(builder, place.candidates(context))

    if not selected then
        return nil
    end

    local vault = catalog.get(selected.id)

    -- Source PLACE can select a mapless serial controller. Its post-place
    -- hook owns child selection, so it must not enter the geometry fitter.
    if #vault.rows == 0 then
        if not place_controller then
            error("mapless PLACE vault needs a controller runner")
        end

        if place_controller(ctx, builder, context, placed, vault) then
            return vault.id
        end

        return nil
    end

    local map = fit(ctx, builder, vault, context)

    if not map then
        return nil
    end

    placed[#placed + 1] = map
    context.used:add_map(vault, map)

    return vault.id
end

return place
