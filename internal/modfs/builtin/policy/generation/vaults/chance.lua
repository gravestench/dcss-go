-- Source CHANCE maps roll independently, then place in shuffled order.
local categories = require("constants.catalog")
local chance_units = require("constants.vault_chance")
local depth = require("policy.generation.vaults.depth")
local selection = require("policy.generation.vaults.selection")

local chance = {}

-- A chance_* tag ties alternative maps to one chance roll. Sorting tag
-- names makes even an unusual map with two such tags deterministic.
function chance.group_tag(definition)
    local tags = {}

    for tag in pairs(definition.tags) do
        if tag:sub(1, 7) == "chance_" then
            tags[#tags + 1] = tag
        end
    end

    table.sort(tags)

    return tags[1]
end

-- Source fallback maps replace a failed chance_* fit by the matching
-- fallback_* tag. The fallback has its own weight and geometric attempt.
function chance.fallback_tag(definition)
    local tag = chance.group_tag(definition)

    if tag then
        return "fallback_" .. tag:sub(8)
    end

    return nil
end

-- Source layout_* tags admit only their named layout families, while
-- nolayout_* tags veto a family. A nil family is useful to catalog tests
-- that inspect chance syntax outside a generated floor.
function chance.layout_allowed(definition, family)
    if not family then
        return true
    end

    local restricted = false
    local accepted = false

    for tag in pairs(definition.tags) do
        local requested = tag:match("^layout_(.+)$")

        if requested then
            restricted = true
            accepted = accepted or requested == family
        end
    end

    return not definition.tags["nolayout_" .. family] and
        (not restricted or accepted)
end

-- Only explicit CHANCE maps join this stage. Ordinary weighted maps and
-- helpers have different selection paths, even if depth.eligible is true.
local function eligible(definition, context)
    return #definition.chances > 0 and
        not definition.tags.dummy and
        chance.layout_allowed(definition, context.layout_family) and
        (not context.used or context.used:allows(definition)) and
        depth.eligible(definition, context.branch_id,
            context.depth, context.branch_bottom)
end

-- Choose one weighted map from a chance_* family after its representative
-- succeeded. The family's other CHANCE declarations do not roll again.
local function family_choice(random, tag, context)
    local request = {}

    for name, value in pairs(context) do
        request[name] = value
    end

    request.family = nil
    request.excluded = nil
    request.exclude_chance = nil
    request.ignore_chance = true

    return selection.choose_tag(random, tag, request)
end

-- Shuffle successful choices so shared uniq_* or luniq_* tags do not favor
-- whichever ID sorts first. The same layout stream drives every draw.
local function shuffle(random, maps)
    for index = #maps, 2, -1 do
        local other = random:roll(index) + 1

        maps[index], maps[other] = maps[other], maps[index]
    end
end

-- Roll representatives in stable ID order, resolve shared chance families,
-- then shuffle successes before the caller attempts geometric placement.
function chance.select(random, context)
    local selected = {}
    local groups = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if eligible(definition, context) then
            local tag = chance.group_tag(definition)

            if not tag or not groups[tag] then
                if tag then
                    groups[tag] = true
                end

                local odds = depth.chance(definition, context.branch_id,
                    context.depth, context.branch_bottom)

                if odds == chance_units.ROLL or
                    (odds > 0 and random:roll(chance_units.ROLL) < odds) then
                    local chosen = tag and family_choice(random, tag, context)
                        or definition

                    if chosen then
                        selected[#selected + 1] = chosen
                    end
                end
            end
        end
    end

    shuffle(random, selected)

    return selected
end

return chance
