local capabilities = require("constants.mutation_capabilities")
local schools = require("constants.spell_schools")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")

local enhancers = {}

local function has_school(spell, wanted)
    for _, school in ipairs(spell.schools) do
        if school == wanted then
            return true
        end
    end

    return false
end

function enhancers.hex(level, _, _, spell)
    if has_school(spell, schools.HEXES) then
        return level
    end

    return 0
end

function enhancers.necromancy(level, _, _, spell)
    if has_school(spell, schools.NECROMANCY) then
        return level
    end

    return 0
end

effects.add(mutations.MUT_HEX_ENHANCER, {
    [capabilities.SPELL_ENHANCER] = enhancers.hex,
})

effects.add(mutations.MUT_NECRO_ENHANCER, {
    [capabilities.SPELL_ENHANCER] = enhancers.necromancy,
})

return enhancers
