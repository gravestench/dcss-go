local catalog = require("policy.catalog")
local cap = require("policy.magic.cap")
local formulas = require("policy.character.formulas")
local mutation_effects = require("policy.mutations.effects.registry")
local mutation_capabilities = require("constants.mutation_capabilities")
local player_attributes = require("policy.character.attributes")
local schools = require("constants.spell_schools")
local skill_ids = require("ids.skills")
local enhancement = require("policy.magic.enhancement")
local horror = require("policy.character.horror")

local power = {}

local school_skills = {
    [schools.CONJURATION] = skill_ids.SK_CONJURATIONS,
    [schools.HEXES] = skill_ids.SK_HEXES,
    [schools.SUMMONING] = skill_ids.SK_SUMMONINGS,
    [schools.NECROMANCY] = skill_ids.SK_NECROMANCY,
    [schools.TRANSLOCATION] = skill_ids.SK_TRANSLOCATIONS,
    [schools.TRANSMUTATION] = skill_ids.SK_TRANSMUTATIONS,
    [schools.FIRE] = skill_ids.SK_FIRE_MAGIC,
    [schools.ICE] = skill_ids.SK_ICE_MAGIC,
    [schools.AIR] = skill_ids.SK_AIR_MAGIC,
    [schools.EARTH] = skill_ids.SK_EARTH_MAGIC,
    [schools.POISON] = skill_ids.SK_POISON_MAGIC,
}

-- Apply species aptitude before scaling each trained school; forbidden skills contribute zero.
local function scaled_skill(ctx, player, skills, species, id, scale)
    local aptitude = species.aptitudes[id]

    if not aptitude or not aptitude.allowed then
        return 0
    end

    for _, skill in ipairs(skills.entries) do
        if skill.id == id then
            return formulas.scaled_skill(skill, scale,
                formulas.effective_skill_aptitude(ctx, player, species, id))
        end
    end

    return 0
end

-- Read the same aptitude-adjusted skill scale used by both failure and cast power.
function power.training(ctx, player, id, scale)
    local character = ctx:get(player, "core.player")
    local skills = ctx:get(player, "core.skills")

    if not character or not skills then
        error("player lacks skill state")
    end

    local species = catalog.get("species", character.species_id)

    return scaled_skill(ctx, player, skills, species, id, scale)
end

-- Source: spl-cast.cc:_skill_power. Schools are averaged before the
-- Spellcasting contribution; innate casters use Spellcasting instead.
function power.skill(ctx, player, spell)
    local character = ctx:get(player, "core.player")
    local skills = ctx:get(player, "core.skills")

    if not character or not skills then
        error("player lacks spell power state")
    end

    local species = catalog.get("species", character.species_id)
    local sum = 0
    local count = 0

    for _, school in ipairs(spell.schools) do
        if school ~= schools.NONE then
            local skill_id = school_skills[school]

            if not skill_id then
                error("unknown spell school " .. school)
            end

            sum = sum + scaled_skill(ctx, player, skills, species,
                skill_id, 200)
            count = count + 1
        end
    end

    local school_power = 0

    if count > 0 then
        school_power = math.floor(sum / count)
    end

    local spellcasting_scale = 50 + mutation_effects.sum(ctx, player,
        mutation_capabilities.SPELLCASTING_SCALE_BONUS)

    return school_power +
        scaled_skill(ctx, player, skills, species,
            skill_ids.SK_SPELLCASTING, spellcasting_scale)
end

-- Source: spl-cast.cc:calc_spell_power(fail_rate_check=true, scale=6).
-- This path deliberately excludes intelligence, enhancers, and power caps.
function power.failure(ctx, player, spell)
    return math.floor(power.skill(ctx, player, spell) * 6 / 100)
end

-- Source: spl-cast.cc:calc_spell_power and _stepdown_spellpower, with the
-- ordinary scale-one cast path. Wielded staff enhancement is included in
-- enhancement.apply alongside mutation and brilliance effects.
function power.cast(ctx, player, spell)
    local attributes = player_attributes.current(ctx, player)
    local character = ctx:get(player, "core.player")

    if not attributes or not character then
        error("player lacks cast power state")
    end

    local centis = math.floor(power.skill(ctx, player, spell) *
        attributes.intelligence / 10)
    centis = enhancement.apply(ctx, player, spell, centis)
    local wild = mutation_effects.sum(ctx, player,
        mutation_capabilities.SPELL_POWER_GAIN)
    local subdued = mutation_effects.sum(ctx, player,
        mutation_capabilities.SPELL_POWER_LOSS)

    centis = math.floor(centis * (10 + wild) / (10 + subdued))

    local augmentation = mutation_effects.sum(ctx, player,
        mutation_capabilities.AUGMENTATION)
    centis = math.floor(centis * (10 + 4 * augmentation) / 10)
    centis = horror.spell_power(centis, horror.penalty(ctx, player))

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

-- Example: one spell request returns both its failure-scale power and capped cast power.
-- Return both failure and cast scales for the same catalog spell and live player state.
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
