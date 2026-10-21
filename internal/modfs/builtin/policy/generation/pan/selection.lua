-- Theory of operation: each visit to Pandemonium chooses one mandatory
-- primary vault. The source first gives unseen lords a growing chance,
-- then draws an ordinary map if that special choice did not occur. Both
-- pools come from the effective DES catalog, including layered mods.
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local categories = require("constants.catalog")
local tags = require("constants.vault_tags")
local eligibility = require("policy.generation.vaults.eligibility")
local used_maps = require("policy.generation.vaults.used")
local weights = require("policy.generation.vaults.weight")

local selection = {}

local LORDS = {
    {
        map = tags.PAN_LORD_MNOLEG,
        unique = tags.UNIQ_PAN_MNOLEG,
    },
    {
        map = tags.PAN_LORD_LOM_LOBON,
        unique = tags.UNIQ_PAN_LOM_LOBON,
    },
    {
        map = tags.PAN_LORD_CEREBOV,
        unique = tags.UNIQ_PAN_CEREBOV,
    },
    {
        map = tags.PAN_LORD_GLOORX_VLOQ,
        unique = tags.UNIQ_PAN_GLOORX_VLOQ,
    },
}

-- Build the source random-depth pool without incidental mini or extra
-- vaults. A dummy can balance optional placement but cannot fulfill Pan's
-- mandatory primary; selecting it would produce an empty region.
function selection.candidates(history, required_tag)
    catalog.load()

    local context = {
        branch_id = branches.BRANCH_PANDEMONIUM,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 24,
        used = history.used or used_maps.new(history.prior_vault_ids),
    }
    local candidates = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)
        -- Forced lord realms use the source tag selector, which admits
        -- unrand maps. The ordinary depth selector deliberately excludes
        -- them until the lord-pressure decision has chosen their tag.
        local source_eligible

        if required_tag then
            source_eligible = eligibility.tag(definition, context)
        else
            source_eligible = eligibility.depth(definition, context)
        end
        local eligible = definition.family == "pan" and
            not definition.tags.extra and
            not definition.tags.minivault and
            not definition.tags.dummy and
            #definition.chances == 0 and
            (not required_tag or definition.tags[required_tag]) and
            source_eligible

        if eligible then
            local weight = weights.for_branch(definition,
                context.branch_id, context.depth,
                context.branch_bottom, context.absolute_depth)

            if weight > 0 then
                candidates[#candidates + 1] = {
                    definition = definition,
                    weight = weight,
                }
            end
        end
    end

    table.sort(candidates, function(left, right)
        return left.definition.id < right.definition.id
    end)

    return candidates
end

-- Make one weighted draw after sorting by stable map ID. Reordering files
-- inside a mod layer cannot change which map a saved RNG state selects.
local function choose_weighted(random, candidates)
    local total = 0

    for _, candidate in ipairs(candidates) do
        total = total + candidate.weight
    end

    if total == 0 then
        error("Pandemonium has no eligible primary vault")
    end

    local draw = random:roll(total)

    for _, candidate in ipairs(candidates) do
        if draw < candidate.weight then
            return candidate.definition
        end

        draw = draw - candidate.weight
    end

    error("Pandemonium primary draw exceeded the catalog")
end

-- The source increases unseen-lord pressure with regions seen. Its second
-- draw repeatedly samples four lord identities until one is still unseen.
-- Previously generated uniq_* tags come from saved vault IDs, not a Lua
-- module global that would disappear on restore.
local function pressured_lord(random, history, used)
    local unseen_count = 0

    for _, lord in ipairs(LORDS) do
        if not used.run_tags[lord.unique] then
            unseen_count = unseen_count + 1
        end
    end

    if unseen_count == 0 then
        return nil
    end

    local seen = history.levels_seen or 0

    if random:roll(20 + seen) >= 1 + seen then
        return nil
    end

    while true do
        local lord = LORDS[random:roll(#LORDS) + 1]

        if not used.run_tags[lord.unique] then
            return lord.map
        end
    end
end

-- Select a source primary for one fresh Pan region. The caller passes a
-- saved history and a bounded game RNG, then records the selected map only
-- after the full region fits and portal transit succeeds.
function selection.choose(random, history)
    local used = history.used or used_maps.new(history.prior_vault_ids)
    local tag = pressured_lord(random, history, used)
    local candidates = selection.candidates({ used = used }, tag)

    return choose_weighted(random, candidates)
end

return selection
