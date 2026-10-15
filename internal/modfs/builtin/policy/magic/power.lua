local catalog = require("policy.catalog")
local cap = require("policy.magic.cap")
local formulas = require("policy.character.formulas")
local traits = require("policy.character.traits")

local power = {}

local school_skills = {
    conjuration = "SK_CONJURATIONS",
    hexes = "SK_HEXES",
    summoning = "SK_SUMMONINGS",
    necromancy = "SK_NECROMANCY",
    translocation = "SK_TRANSLOCATIONS",
    transmutation = "SK_TRANSMUTATIONS",
    fire = "SK_FIRE_MAGIC",
    ice = "SK_ICE_MAGIC",
    air = "SK_AIR_MAGIC",
    earth = "SK_EARTH_MAGIC",
    poison = "SK_POISON_MAGIC",
}

local function scaled_skill(skills, species, id, scale)
    local aptitude = species.aptitudes[id]

    if not aptitude or not aptitude.allowed then
        return 0
    end

    for _, skill in ipairs(skills.entries) do
        if skill.id == id then
            return formulas.scaled_skill(skill, scale, aptitude.value)
        end
    end

    return 0
end

function power.training(ctx, player, id, scale)
    local character = ctx:get(player, "core.player")
    local skills = ctx:get(player, "core.skills")

    if not character or not skills then
        error("player lacks skill state")
    end

    local species = catalog.get("species", character.species_id)

    return scaled_skill(skills, species, id, scale)
end

-- Source: spl-cast.cc:_skill_power. Schools are averaged before the
-- Spellcasting contribution; innate casters use Spellcasting instead.
function power.skill(ctx, player, spell)
    local character = ctx:get(player, "core.player")
    local progression = ctx:get(player, "core.progression")
    local skills = ctx:get(player, "core.skills")

    if not character or not progression or not skills then
        error("player lacks spell power state")
    end

    local species = catalog.get("species", character.species_id)
    local sum = 0
    local count = 0

    for _, school in ipairs(spell.schools) do
        if school ~= "none" then
            local skill_id = school_skills[school]

            if not skill_id then
                error("unknown spell school " .. school)
            end

            sum = sum + scaled_skill(skills, species, skill_id, 200)
            count = count + 1
        end
    end

    local school_power = 0

    if count > 0 then
        school_power = math.floor(sum / count)
    end

    local spellcasting_scale = 50

    if traits.mutation_level(species, "MUT_INNATE_CASTER",
        progression.level) > 0 then
        spellcasting_scale = 250
    end

    return school_power +
        scaled_skill(skills, species, "SK_SPELLCASTING", spellcasting_scale)
end

-- Source: spl-cast.cc:calc_spell_power(fail_rate_check=true, scale=6).
-- This path deliberately excludes intelligence, enhancers, and power caps.
function power.failure(ctx, player, spell)
    return math.floor(power.skill(ctx, player, spell) * 6 / 100)
end

-- Source: spl-cast.cc:calc_spell_power and _stepdown_spellpower, with the
-- ordinary scale-one cast path. Equipment enhancers are applied separately
-- when their equipment effects enter the Lua ruleset.
function power.cast(ctx, player, spell)
    local attributes = ctx:get(player, "core.attributes")
    local character = ctx:get(player, "core.player")
    local progress = ctx:get(player, "core.progression")

    if not attributes or not character or not progress then
        error("player lacks cast power state")
    end

    local species = catalog.get("species", character.species_id)
    local centis = math.floor(power.skill(ctx, player, spell) *
        attributes.intelligence / 10)
    local wild = traits.mutation_level(species, "MUT_WILD_MAGIC",
        progress.level)
    local subdued = traits.mutation_level(species, "MUT_SUBDUED_MAGIC",
        progress.level)

    centis = math.floor(centis * (10 + 3 * wild) / (10 + 3 * subdued))

    local millis = centis * 10

    if millis >= 50000 then
        local stepped = 50000 *
            math.log(1 + millis / 50000) / math.log(2)

        millis = math.min(200000, math.floor(stepped))
    end

    local result = math.floor(millis / 1000)

    local spell_cap = cap.for_spell(spell)

    if spell_cap > 0 then
        result = math.min(result, spell_cap)
    end

    return result
end

function power.run_policy(ctx, input)
    local spell = catalog.get("spells", input.spell_id)

    return {
        failure_power6 = power.failure(ctx, ctx:player(), spell),
        cast_power = power.cast(ctx, ctx:player(), spell),
    }
end

register.policy({
    id = "magic.spell_power",
    run = power.run_policy,
})

return power
