-- Theory of operation: a candidate's mutation is checked against the
-- player's current ranks, species, and innate conflicts before selection.
-- Reservoir sampling follows the source's one-chance-in-seen algorithm;
-- duplicate entries stay meaningful and each valid draw uses religion RNG.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local conflict_rows = require("data.mutation_conflicts")
local sacrificed_skills = require("data.ru_skill_sacrifices")
local component = require("constants.component")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local pools = require("constants.ru_variant_pools")
local physiology = require("policy.mutations.physiology")
local records = require("policy.mutations.records")
local source_pools = require("data.ru_variant_mutations")
local streams = require("constants.rng_streams")

local variants = {}

-- An innate opposing rank cannot be traded away by accepting a sacrifice.
local function innate_conflict(ctx, player, id)
    for _, row in ipairs(conflict_rows) do
        local other

        if row.first == id then
            other = row.second
        elseif row.second == id then
            other = row.first
        end

        if other then
            local entry = records.find(ctx, player, other)

            if entry and entry.state.innate > 0 then
                return true
            end
        end
    end

    return false
end

-- Check a single mutation without spending RNG, allowing a whole candidate
-- pool to be inspected before any offer-selection draw is consumed.
function variants.valid(ctx, player, id)
    local definition = catalog.get(categories.MUTATIONS, id)

    if levels.base(ctx, player, id) >= definition.max_level or
        innate_conflict(ctx, player, id) or
        not physiology.permitted(ctx, player, id) then
        return false
    end

    local skill_id = sacrificed_skills[id]

    if skill_id then
        local identity = ctx:get(player, component.PLAYER)
        local species = catalog.get(categories.SPECIES,
            identity.species_id)
        local aptitude = species.aptitudes[skill_id]

        if not aptitude or not aptitude.allowed then
            return false
        end
    end

    if id == mutations.MUT_NO_SUMMONING_MAGIC and
        levels.base(ctx, player, mutations.MUT_NO_LOVE) > 0 then
        return false
    end

    if id == mutations.MUT_INHIBITED_REGENERATION and
        levels.base(ctx, player, mutations.MUT_VAMPIRISM) > 0 then
        return false
    end

    if id == mutations.MUT_NO_POTION_HEAL and
        levels.base(ctx, player, mutations.MUT_NO_DRINK) > 0 then
        return false
    end

    return true
end

-- Walk in committed source order; each valid member may replace the current
-- choice with probability one over the number seen so far.
local function choose_one(ctx, player, pool)
    local seen = 0
    local chosen

    for _, id in ipairs(pool) do
        if variants.valid(ctx, player, id) then
            seen = seen + 1

            if ctx:random(streams.RELIGION, seen) == 0 then
                chosen = id
            end
        end
    end

    return chosen
end

-- Arcana must have one valid school at each severity; an incomplete set is
-- unavailable. The other three source vectors each choose one mutation.
function variants.choose(ctx, player, pool_id)
    local pool = source_pools[pool_id]

    if not pool then
        error("unknown Ru variant pool " .. tostring(pool_id))
    end

    if pool_id ~= pools.ARCANA then
        local chosen = choose_one(ctx, player, pool)

        return chosen and { chosen } or nil
    end

    local chosen = {}

    for _, severity in ipairs(pool) do
        local id = choose_one(ctx, player, severity)

        if not id then
            return nil
        end

        chosen[#chosen + 1] = id
    end

    return chosen
end

-- Skip RNG when a definition cannot possibly yield its required mutation.
function variants.possible(ctx, player, definition)
    if definition.mutation_id then
        return variants.valid(ctx, player, definition.mutation_id)
    end

    local pool = source_pools[definition.variant_pool]

    if not pool then
        return false
    end

    if definition.variant_pool ~= pools.ARCANA then
        for _, id in ipairs(pool) do
            if variants.valid(ctx, player, id) then
                return true
            end
        end

        return false
    end

    for _, severity in ipairs(pool) do
        local any = false

        for _, id in ipairs(severity) do
            any = any or variants.valid(ctx, player, id)
        end

        if not any then
            return false
        end
    end

    return true
end

return variants
