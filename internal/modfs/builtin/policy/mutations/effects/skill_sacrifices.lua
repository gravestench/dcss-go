local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")
local schools = require("constants.spell_schools")
local skills = require("ids.skills")

local sacrifices = {}

-- Source: skills.cc:skill_sac_muts and spl-util.cc:arcana_sacrifice_map.
local restrictions = {
    {
        mutation = mutations.MUT_NO_AIR_MAGIC,
        skill = skills.SK_AIR_MAGIC,
        school = schools.AIR,
    },
    {
        mutation = mutations.MUT_NO_FIRE_MAGIC,
        skill = skills.SK_FIRE_MAGIC,
        school = schools.FIRE,
    },
    {
        mutation = mutations.MUT_NO_EARTH_MAGIC,
        skill = skills.SK_EARTH_MAGIC,
        school = schools.EARTH,
    },
    {
        mutation = mutations.MUT_NO_ICE_MAGIC,
        skill = skills.SK_ICE_MAGIC,
        school = schools.ICE,
    },
    {
        mutation = mutations.MUT_NO_POISON_MAGIC,
        skill = skills.SK_POISON_MAGIC,
        school = schools.POISON,
    },
    {
        mutation = mutations.MUT_NO_HEXES_MAGIC,
        skill = skills.SK_HEXES,
        school = schools.HEXES,
    },
    {
        mutation = mutations.MUT_NO_TRANSLOCATION_MAGIC,
        skill = skills.SK_TRANSLOCATIONS,
        school = schools.TRANSLOCATION,
    },
    {
        mutation = mutations.MUT_NO_TRANSMUTATION_MAGIC,
        skill = skills.SK_TRANSMUTATIONS,
        school = schools.TRANSMUTATION,
    },
    {
        mutation = mutations.MUT_NO_CONJURATION_MAGIC,
        skill = skills.SK_CONJURATIONS,
        school = schools.CONJURATION,
    },
    {
        mutation = mutations.MUT_NO_NECROMANCY_MAGIC,
        skill = skills.SK_NECROMANCY,
        school = schools.NECROMANCY,
    },
    {
        mutation = mutations.MUT_NO_SUMMONING_MAGIC,
        skill = skills.SK_SUMMONINGS,
        school = schools.SUMMONING,
    },
    {
        mutation = mutations.MUT_NO_DODGING,
        skill = skills.SK_DODGING,
    },
    {
        mutation = mutations.MUT_NO_ARMOUR_SKILL,
        skill = skills.SK_ARMOUR,
    },
    {
        mutation = mutations.MUT_NO_ARTIFICE,
        skill = skills.SK_EVOCATIONS,
    },
    {
        mutation = mutations.MUT_NO_STEALTH,
        skill = skills.SK_STEALTH,
    },
    {
        mutation = mutations.MUT_MISSING_HAND,
        skill = skills.SK_SHIELDS,
    },
    {
        mutation = mutations.MUT_NO_LOVE,
        skill = skills.SK_SUMMONINGS,
    },
}

-- One predicate serves both a forbidden skill and, when present, its paired spell school.
local function matching(subject)
    -- Capture the one forbidden skill or school in a handler. The registry
    -- passes the requested ID later, after the sacrifice level is known.
    return function(level, _, _, requested)
        return level > 0 and requested == subject and 1 or 0
    end
end

-- Gaining No Air Magic, for example, sanitizes any training selection made before that sacrifice.
-- Example: gaining No Air Magic sanitizes a previously selected Air Magic training slot.
function sacrifices.on_change(ctx, owner)
    require("policy.character.skill_availability").sanitize(ctx, owner)
end

for _, restriction in ipairs(restrictions) do
    local handlers = {
        [capabilities.SKILL_FORBIDDEN] = matching(restriction.skill),
        [capabilities.ON_CHANGE] = sacrifices.on_change,
    }

    if restriction.school then
        handlers[capabilities.SPELL_SCHOOL_FORBIDDEN] =
            matching(restriction.school)
    end

    if restriction.mutation == mutations.MUT_NO_STEALTH then
        -- Stealth has a direct capability in addition to the general skill
        -- restriction, so both stealth queries and training reject it.
        handlers[capabilities.STEALTH_FORBIDDEN] = function(level)
            return level > 0 and 1 or 0
        end
    end

    registry.add(restriction.mutation, handlers)
end

return sacrifices
