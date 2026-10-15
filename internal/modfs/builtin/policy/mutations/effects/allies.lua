local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")
local schools = require("constants.spell_schools")
local spells = require("ids.spells")

local allies = {}

-- Source: spl-util.cc:casting_uselessness_reason lists the ally spells
-- outside Summoning whose effects Ru's Sacrifice Love forbids.
local ally_spells = {
    [spells.SPELL_ANIMATE_DEAD] = true,
    [spells.SPELL_DEATH_CHANNEL] = true,
    [spells.SPELL_SIMULACRUM] = true,
    [spells.SPELL_INFESTATION] = true,
    [spells.SPELL_TUKIMAS_DANCE] = true,
}

function allies.forbidden(level)
    return level > 0 and 1 or 0
end

function allies.summoning_school(level, _, _, school)
    return level > 0 and school == schools.SUMMONING and 1 or 0
end

function allies.spell(level, _, _, spell_id)
    return level > 0 and ally_spells[spell_id] and 1 or 0
end

registry.add(mutations.MUT_NO_LOVE, {
    [capabilities.ALLIES_FORBIDDEN] = allies.forbidden,
    [capabilities.SPELL_SCHOOL_FORBIDDEN] = allies.summoning_school,
    [capabilities.SPELL_ID_FORBIDDEN] = allies.spell,
})

return allies
