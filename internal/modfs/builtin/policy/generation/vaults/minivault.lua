-- Dungeon minivaults are weighted, depth-qualified DES maps without an
-- explicit ORIENT. A selected extra map asks for another draw; a regular
-- map or a source dummy ends this stage.
local catalog = require("policy.generation.vaults.catalog")
local categories = require("constants.catalog")
local chance_units = require("constants.vault_chance")
local depth = require("policy.generation.vaults.depth")
local eligibility = require("policy.generation.vaults.eligibility")
local weights = require("policy.generation.vaults.weight")

local minivault = {}
local MAX_EXTRA_DRAWS = 10000

-- Build the eligible source pool once per floor in stable ID order. A
-- depthless tagged helper can still serve its controller, but stays out
-- of this ordinary draw; CHANCE controllers have their own earlier stage.
function minivault.candidates(context)
    local candidates = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)
        local chance_only = definition.tags.dummy and
            #definition.chances > 0
        local weight = weights.for_branch(definition,
            context.branch_id, context.depth, context.branch_bottom)

        if definition.tags.minivault and
            eligibility.depth(definition, context) and
            (chance_only or #definition.chances == 0) and
            (chance_only or weight > 0) then
            candidates[#candidates + 1] = {
                definition = definition,
                weight = weight,
                chance_only = chance_only,
            }
        end
    end

    return candidates
end

-- A source dummy with CHANCE can suppress a draw before the weighted
-- candidates are considered. Afterwards, one bounded roll picks by
-- cumulative weight; choosing a weighted dummy also means no map.
function minivault.choose(random, candidates, context)
    local total = 0

    for _, candidate in ipairs(candidates) do
        if (not context.used or
            context.used:allows(candidate.definition)) then
            if candidate.chance_only then
                local odds = depth.chance(candidate.definition,
                    context.branch_id, context.depth,
                    context.branch_bottom, context.absolute_depth)

                if odds == chance_units.ROLL or
                    (odds > 0 and random:roll(chance_units.ROLL) < odds) then
                    return nil
                end
            else
                total = total + candidate.weight
            end
        end
    end

    if total == 0 then
        return nil
    end

    local draw = random:roll(total)

    for _, candidate in ipairs(candidates) do
        if not candidate.chance_only and
            (not context.used or
                context.used:allows(candidate.definition)) then
            if draw < candidate.weight then
                return not candidate.definition.tags.dummy and
                    candidate.definition or nil
            end

            draw = draw - candidate.weight
        end
    end

    error("minivault weight selection exceeded the catalog")
end

-- Place each selected map before the next draw so its name and uniqueness
-- tags constrain later candidates. The explicit cap prevents an all-extra
-- pool from looping indefinitely when every fit fails.
function minivault.place(ctx, builder, context, placed, place,
    place_controller)
    local candidates = minivault.candidates(context)
    local primary

    for _ = 1, MAX_EXTRA_DRAWS do
        local selected = minivault.choose(builder, candidates, context)

        if not selected then
            break
        end

        local vault = catalog.get(selected.id)
        local successful = false

        if #vault.rows == 0 then
            if not place_controller then
                error("mapless minivault needs a controller runner")
            end

            successful = place_controller(ctx, builder, context,
                placed, vault)
        else
            local map = place(ctx, builder, vault, context)

            if map then
                placed[#placed + 1] = map
                context.used:add(vault)
                successful = true
            end
        end

        if successful then
            primary = primary or vault.id
        end

        if not selected.tags.extra then
            break
        end
    end

    return primary
end

return minivault
