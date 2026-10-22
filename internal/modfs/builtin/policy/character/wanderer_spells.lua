-- Example: A magic gift excludes spells the species cannot cast at the starting level.
-- Source: ng-wanderer.cc. Magic gifts draw from the committed spell catalog.
local spells = {}
local player_books = require("policy.magic.player_book_catalog")
local school_ids = require("constants.spell_schools")
local skill_ids = require("ids.skills")
local streams = require("constants.rng_streams")
local traits = require("policy.character.traits")

local schools = {
    [skill_ids.SK_CONJURATIONS] = school_ids.CONJURATION,
    [skill_ids.SK_HEXES] = school_ids.HEXES,
    [skill_ids.SK_SUMMONINGS] = school_ids.SUMMONING,
    [skill_ids.SK_NECROMANCY] = school_ids.NECROMANCY,
    [skill_ids.SK_TRANSLOCATIONS] = school_ids.TRANSLOCATION,
    [skill_ids.SK_TRANSMUTATIONS] = school_ids.TRANSMUTATION,
    [skill_ids.SK_FIRE_MAGIC] = school_ids.FIRE,
    [skill_ids.SK_ICE_MAGIC] = school_ids.ICE,
    [skill_ids.SK_AIR_MAGIC] = school_ids.AIR,
    [skill_ids.SK_EARTH_MAGIC] = school_ids.EARTH,
    [skill_ids.SK_POISON_MAGIC] = school_ids.POISON,
}

-- Source skill-type order controls Spellcasting's fallback school draw.
local magic_skills = {
    skill_ids.SK_CONJURATIONS,
    skill_ids.SK_HEXES,
    skill_ids.SK_SUMMONINGS,
    skill_ids.SK_NECROMANCY,
    skill_ids.SK_TRANSLOCATIONS,
    skill_ids.SK_TRANSMUTATIONS,
    skill_ids.SK_FIRE_MAGIC,
    skill_ids.SK_ICE_MAGIC,
    skill_ids.SK_AIR_MAGIC,
    skill_ids.SK_EARTH_MAGIC,
    skill_ids.SK_POISON_MAGIC,
}

-- Recognize Spellcasting and schools before choosing a magic gift path.
function spells.is_magic_skill(id)
    return id == skill_ids.SK_SPELLCASTING or schools[id] ~= nil
end

-- Djinni's source reroll includes Spellcasting itself; other results use
-- the exact skill enum order before the gift branch is selected.
function spells.djinni_skill(ctx)
    local choices = { skill_ids.SK_SPELLCASTING }

    for _, id in ipairs(magic_skills) do
        choices[#choices + 1] = id
    end

    return choices[ctx:random(streams.WANDERER, #choices) + 1]
end

-- Check spell schools without assuming every spell lists that school.
local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Skip already chosen or species-forbidden spells before reservoir selection.
local function eligible(ctx, species, spell, school, minimum, maximum,
    seen)
    if not traits.start_spell_usable(ctx, ctx:player(), species,
            spell.id) or seen[spell.id] or
        spell.level < minimum or spell.level > maximum then
        return false
    end

    if contains(spell.flags, "monster") or contains(spell.flags, "testing") then
        return false
    end

    return not school or contains(spell.schools, school)
end

-- Major gifts reservoir-sample each source-ordered eligible spell.
local function pick(ctx, species, school, minimum, maximum, seen,
    candidates)
    local chosen
    local count = 0

    for _, spell in ipairs(candidates) do
        if eligible(ctx, species, spell, school, minimum, maximum,
            seen) then
            count = count + 1

            if ctx:random(streams.WANDERER, count) == 0 then
                chosen = spell.id
            end
        end
    end

    if chosen then
        seen[chosen] = true
    end

    return chosen
end

-- The first minor-book spell must leave at least one distinct partner
-- whose level completes four. Source then draws uniformly among partners.
local function minor_pair(ctx, species, school, candidates)
    local available = {}

    for _, spell in ipairs(candidates) do
        if eligible(ctx, species, spell, school, 1, 3, {}) then
            available[#available + 1] = spell
        end
    end

    local first_choices = {}

    for _, first in ipairs(available) do
        for _, second in ipairs(available) do
            if first.id ~= second.id and
                first.level + second.level == 4 then
                first_choices[#first_choices + 1] = first
                break
            end
        end
    end

    if #first_choices == 0 then
        return {}
    end

    local first = first_choices[
        ctx:random(streams.WANDERER, #first_choices) + 1]
    local second_choices = {}

    for _, second in ipairs(available) do
        if second.id ~= first.id and
            first.level + second.level == 4 then
            second_choices[#second_choices + 1] = second
        end
    end

    local second = second_choices[
        ctx:random(streams.WANDERER, #second_choices) + 1]

    return { first.id, second.id }
end

-- Strong gifts offer several spells; minor gifts build a themed exact-four
-- pair, with a random magic school when the role was Spellcasting.
function spells.gift(ctx, species, skill, good)
    local school = schools[skill]
    local chosen = {}
    local seen = {}
    local candidates = player_books.ordered()

    if good then
        local count = skill == skill_ids.SK_SPELLCASTING and 4 or 3
        local maximum = skill == skill_ids.SK_SPELLCASTING and 3 or 4

        for index = 1, count do
            local limit = index == 1 and 1 or maximum
            local id = pick(ctx, species, school, 1, limit, seen,
                candidates)

            if id then
                chosen[#chosen + 1] = id
            end
        end
    else
        if skill == skill_ids.SK_SPELLCASTING then
            local chosen_skill = magic_skills[
                ctx:random(streams.WANDERER, #magic_skills) + 1]

            school = schools[chosen_skill]
        end

        chosen = minor_pair(ctx, species, school, candidates)
    end

    return chosen
end

return spells
