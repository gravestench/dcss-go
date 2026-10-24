-- Theory of operation: Ru quotes the lasting cost of a sacrifice when it
-- creates the offer. The mutation choice and the quoted part are saved;
-- ordinary skill value is calculated again when a player accepts later.
-- Bundled source exceptions have short named functions below. A modded
-- definition can name its own price module without editing this owner.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local conflict_rows = require("data.mutation_conflicts")
local formulas = require("policy.character.formulas")
local ids = require("ids.ru_sacrifices")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local pools = require("constants.ru_variant_pools")
local records = require("policy.mutations.records")
local sacrificed_skills = require("data.ru_skill_sacrifices")
local size = require("constants.size")
local skills = require("ids.pinned_skills")
local species_ids = require("ids.species")
local streams = require("constants.rng_streams")

local pricing = {}

-- The source bases a sacrificed skill's value on its achieved level and
-- aptitude, not on unspent XP. Distributed Training makes that value zero.
local function skill_value(ctx, player, skill_id)
    if not skill_id or
        levels.base(ctx, player,
            mutations.MUT_DISTRIBUTED_TRAINING) > 0 then
        return 0
    end

    local identity = ctx:get(player, component.PLAYER)
    local trained = ctx:get(player, component.SKILLS)

    if not identity or not trained then
        return 0
    end

    local species = catalog.get(categories.SPECIES,
        identity.species_id)
    local aptitude = species.aptitudes[skill_id]

    if not aptitude or not aptitude.allowed then
        return 0
    end

    -- Source is_useless_skill also rejects a permanently sacrificed
    -- skill even if its former points have not yet been sanitized.
    for mutation_id, sacrificed_id in pairs(sacrificed_skills) do
        if sacrificed_id == skill_id and
            levels.base(ctx, player, mutation_id) > 0 then
            return 0
        end
    end

    if (skill_id == skills.SK_SUMMONINGS and
        levels.base(ctx, player, mutations.MUT_NO_LOVE) > 0) or
        (skill_id == skills.SK_SHIELDS and
            levels.base(ctx, player, mutations.MUT_MISSING_HAND) > 0) then
        return 0
    end

    for _, entry in ipairs(trained.entries) do
        if entry.id == skill_id then
            local effective = formulas.effective_skill_aptitude(ctx,
                player, species, skill_id)

            return math.floor(formulas.skill_points_needed(
                entry.level, effective) / 500)
        end
    end

    return 0
end

-- Score a base stat by how many of the three base stats outrank it.
local function stat_value(ctx, player, wanted, multiplier)
    local base = ctx:get(player, component.ATTRIBUTES)

    if not base then
        return 0
    end

    local rank = 3

    for _, field in ipairs({
        "strength", "intelligence", "dexterity",
    }) do
        if base[field] > base[wanted] then
            rank = rank - 1
        end
    end

    return rank * multiplier
end

-- Source actor::skill_rdiv draws a random rounded fraction at scale 256.
-- A missing skill record means no learned skill value yet.
local function half_skill(ctx, player, skill_id)
    local trained = ctx:get(player, component.SKILLS)
    local identity = ctx:get(player, component.PLAYER)

    if not trained or not identity then
        return 0
    end

    local species = catalog.get(categories.SPECIES,
        identity.species_id)

    for _, entry in ipairs(trained.entries) do
        if entry.id == skill_id then
            local aptitude = formulas.effective_skill_aptitude(ctx,
                player, species, skill_id)
            local numerator = formulas.scaled_skill(entry, 256,
                aptitude)
            local whole = math.floor(numerator / 512)
            local remainder = numerator % 512

            if remainder == 0 then
                return whole
            end

            return whole + (ctx:random(streams.RELIGION,
                512) < remainder and 1 or 0)
        end
    end

    return 0
end

-- Health variants differ sharply: Frail cuts HP while physical
-- vulnerability costs more than slower reflexes.
local function health(ctx, player, selected, amount)
    if selected[1] == mutations.MUT_FRAIL then
        return amount + 10
    end

    if selected[1] == mutations.MUT_PHYSICAL_VULNERABILITY then
        return amount + 5
    end

    return amount
end

-- Magic loss, will loss, and anti-wizardry use three distinct source costs.
local function essence(ctx, player, selected, amount)
    local id = selected[1]

    if id == mutations.MUT_LOW_MAGIC then
        return amount + 10 + math.max(
            half_skill(ctx, player, skills.SK_INVOCATIONS),
            half_skill(ctx, player, skills.SK_SPELLCASTING))
    end

    if id == mutations.MUT_WEAK_WILLED then
        return amount + 35
    end

    return amount + 2 + stat_value(ctx, player,
        "intelligence", 6) +
        half_skill(ctx, player, skills.SK_SPELLCASTING)
end

-- A lost stat prices its rank, while other mutations cost more at an
-- existing rank. Scream is halved after that value is calculated.
local function purity(ctx, player, selected, amount)
    local id = selected[1]
    local field = {
        [mutations.MUT_WEAK] = "strength",
        [mutations.MUT_DOPEY] = "intelligence",
        [mutations.MUT_CLUMSY] = "dexterity",
    }

    if field[id] then
        amount = amount + 4 + stat_value(ctx, player, field[id], 4)
    else
        local rank = levels.base(ctx, player, id)

        amount = amount + (rank >= 2 and 28 or
            rank == 1 and 21 or 14)
    end

    if id == mutations.MUT_SCREAM then
        amount = math.floor(amount / 2)
    end

    return amount
end

-- Already losing allies makes magical tools less valuable.
local function artifice(ctx, player, selected, amount)
    if levels.base(ctx, player, mutations.MUT_NO_LOVE) > 0 then
        return amount - 10
    end

    return amount
end

-- The second or later Skill sacrifice earns a small additional amount.
local function skill(ctx, player, selected, amount)
    return amount + 7 * levels.base(ctx, player,
        mutations.MUT_UNSKILLED)
end

-- Dodging loss is harder if Armour is already gone or unusable by species.
local function nimbleness(ctx, player, selected, amount)
    if levels.base(ctx, player,
        mutations.MUT_NO_ARMOUR_SKILL) > 0 then
        return amount + 20
    end

    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get(categories.SPECIES,
        identity.species_id)
    local aptitude = species.aptitudes[skills.SK_ARMOUR]

    return amount + (aptitude and aptitude.allowed and 0 or 28)
end

-- Repeated safety losses become cheaper; losing the complementary action
-- altogether makes the remaining safety loss more costly.
local function drink(ctx, player, selected, amount)
    amount = amount - 10 * levels.base(ctx, player,
        mutations.MUT_DRINK_SAFETY)

    local read = records.find(ctx, player,
        mutations.MUT_READ_SAFETY)

    if read and read.state.innate == 2 then
        amount = amount + 10
    end

    return amount
end

-- Words uses the same complementary safety rule, with a No Drink bonus.
local function words(ctx, player, selected, amount)
    amount = amount - 10 * levels.base(ctx, player,
        mutations.MUT_READ_SAFETY)

    local drink_record = records.find(ctx, player,
        mutations.MUT_DRINK_SAFETY)

    if drink_record and drink_record.state.innate == 2 then
        return amount + 10
    end

    if levels.base(ctx, player, mutations.MUT_NO_DRINK) > 0 then
        return amount + 15
    end

    return amount
end

-- Armour loss is more severe when Dodging has already been lost.
local function durability(ctx, player, selected, amount)
    if levels.base(ctx, player, mutations.MUT_NO_DODGING) > 0 then
        return amount + 20
    end

    return amount
end

-- Losing allies becomes nearly irrelevant after both summoning magic and
-- evocables are gone; either one alone halves the source price.
local function love(ctx, player, selected, amount)
    local summoning = levels.base(ctx, player,
        mutations.MUT_NO_SUMMONING_MAGIC) > 0
    local artifice_lost = levels.base(ctx, player,
        mutations.MUT_NO_ARTIFICE) > 0

    if summoning and artifice_lost then
        return 1
    end

    if summoning or artifice_lost then
        return math.floor(amount / 2)
    end

    return amount
end

-- Losing a level is harder under Cowardice. Demonspawn and Djinni also
-- risk losing scheduled traits or spells on the source level schedule.
local function experience(ctx, player, selected, amount)
    if levels.base(ctx, player, mutations.MUT_COWARDICE) > 0 then
        amount = amount + 6
    end

    local identity = ctx:get(player, component.PLAYER)
    local lost = levels.base(ctx, player,
        mutations.MUT_INEXPERIENCED)

    if identity.species_id == species_ids.SP_DEMONSPAWN or
        (identity.species_id == species_ids.SP_DJINNI and
            lost % 2 == 0) then
        amount = amount + 10
    end

    return amount
end

-- Cowardice grows costlier as prior Experience sacrifices reduce level.
local function courage(ctx, player, selected, amount)
    return amount + 6 * levels.base(ctx, player,
        mutations.MUT_INEXPERIENCED)
end

-- These named handlers isolate the exceptions. Every other sacrifice uses
-- the authored base, with skill value handled separately.
local adjustments = {
    [ids.HEALTH] = health,
    [ids.ESSENCE] = essence,
    [ids.PURITY] = purity,
    [ids.ARTIFICE] = artifice,
    [ids.SKILL] = skill,
    [ids.NIMBLENESS] = nimbleness,
    [ids.DRINK] = drink,
    [ids.WORDS] = words,
    [ids.DURABILITY] = durability,
    [ids.LOVE] = love,
    [ids.EXPERIENCE] = experience,
    [ids.COURAGE] = courage,
}

-- A new permanent harmful mutation can erase an opposing positive rank.
-- Source mut_check_conflict returns the first opposing mutation's level.
local function opposing_level(ctx, player, id)
    for _, row in ipairs(conflict_rows) do
        local other

        if row.first == id then
            other = row.second
        elseif row.second == id then
            other = row.first
        end

        if other then
            local rank = levels.base(ctx, player, other)

            if rank > 0 then
                return rank
            end
        end
    end

    return 0
end

-- Source piety has a small random blur, bounded by five points or ten
-- percent. The quote is saved so later inspection spends no extra RNG.
function pricing.quote(ctx, player, definition, selected, include_skill)
    local amount = definition.base_piety
    local adjust = adjustments[definition.id]

    if definition.variant_pool == pools.ARCANA then
        for _, id in ipairs(selected) do
            amount = amount + skill_value(ctx, player,
                sacrificed_skills[id])
        end
    elseif include_skill ~= false then
        amount = amount + pricing.skill_value(ctx, player,
            definition)
    end

    if definition.price_module then
        adjust = require(definition.price_module).adjust
    end

    if adjust then
        amount = adjust(ctx, player, selected, amount)
    end

    if definition.variant_pool == pools.HEALTH or
        definition.variant_pool == pools.ESSENCE or
        definition.variant_pool == pools.PURITY then
        amount = amount * (1 + opposing_level(ctx, player,
            selected[1]))
    end

    local blur = math.min(5, math.floor(amount / 10))

    if blur > 0 then
        amount = amount + ctx:random(streams.RELIGION,
            2 * blur + 1) - blur
    end

    return amount
end

-- Skills can improve between the initial quote and acceptance. Selection
-- and acceptance add their current value without changing the saved quote.
function pricing.skill_value(ctx, player, definition)
    local value = skill_value(ctx, player, definition.skill_id)

    if definition.id == ids.HAND then
        local identity = ctx:get(player, component.PLAYER)
        local species = catalog.get(categories.SPECIES,
            identity.species_id)

        if size.rank[species.size] <= size.rank[size.SMALL] then
            value = value + skill_value(ctx, player,
                skills.SK_STAVES)
        end
    end

    return value
end

return pricing
