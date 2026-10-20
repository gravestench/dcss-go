-- Example: An arrival vault with zero weight is excluded despite its arrival tag.
local categories = require("constants.catalog")
local chance_units = require("constants.vault_chance")
local depth = require("policy.generation.vaults.depth")
local eligibility = require("policy.generation.vaults.eligibility")
local weights = require("policy.generation.vaults.weight")

local selection = {}

-- Arrival selection requires both the arrival tag and positive source weight.
local function eligible(definition)
    return definition.tags and definition.tags.arrival and definition.weight > 0
end

-- A single weighted draw selects among already eligible definitions.
function selection.choose(random, definitions)
    local total = 0

    for _, definition in ipairs(definitions) do
        if eligible(definition) then
            total = total + definition.weight
        end
    end

    if total == 0 then
        error("arrival vault catalog has no weighted candidates")
    end

    local draw = random:roll(total)

    for _, definition in ipairs(definitions) do
        if eligible(definition) then
            if draw < definition.weight then
                return definition
            end

            draw = draw - definition.weight
        end
    end

    error("arrival vault weight selection exceeded the catalog")
end

-- Filter registered vault IDs before weighted arrival selection.
function selection.eligible_ids()
    local result = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if eligible(definition) then
            result[#result + 1] = id
        end
    end

    return result
end

-- Load only eligible definitions in catalog order for the arrival draw.
function selection.choose_catalog(random)
    local definitions = {}

    for _, id in ipairs(selection.eligible_ids()) do
        definitions[#definitions + 1] = register.get(categories.VAULTS, id)
    end

    return selection.choose(random, definitions)
end

-- Tag selection filters branch, depth, and chance before weighting a map.
local function candidates_for_tag(random, tag, context)
    local candidates = {}
    local total = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)
        local map_weight = weights.for_branch(definition, context.branch_id,
            context.depth, context.branch_bottom)

        if definition.tags[tag] and map_weight > 0 and
            (not context.family or definition.family == context.family) and
            (not context.exclude_chance or #definition.chances == 0) and
            eligibility.tag(definition, context) then
            local odds = depth.chance(definition, context.branch_id,
                context.depth, context.branch_bottom,
                context.absolute_depth)

            if context.ignore_chance or odds == chance_units.ROLL or
                (odds > 0 and random:roll(chance_units.ROLL) < odds) then
                total = total + map_weight
                candidates[#candidates + 1] = {
                    definition = definition,
                    weight = map_weight,
                }
            end
        end
    end

    return candidates, total
end

-- Unique placement needs the eligible map count before its separate
-- one-in-five gate. Reuse this exact filter for that source stage.
selection.candidates_for_tag = candidates_for_tag

-- A branch can have no eligible vaults for a tag. Callers can then continue
-- normal level generation without consuming another weighted-choice draw.
-- Filter by tag and depth before weighted choice; an empty pool leaves generation on its ordinary path.
function selection.choose_tag(random, tag, context)
    local candidates, total = candidates_for_tag(random, tag, context)

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

    error("vault tag weight selection exceeded the catalog")
end

return selection
