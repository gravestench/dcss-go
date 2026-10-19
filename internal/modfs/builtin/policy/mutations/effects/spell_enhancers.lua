local capabilities = require("constants.mutation_capabilities")
local schools = require("constants.spell_schools")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")

local enhancers = {}

-- Multi-school spells receive an enhancer when any listed school matches;
-- scanning the spell's catalog schools avoids duplicating that decision in
-- each mutation handler.
local function has_school(spell, wanted)
    for _, school in ipairs(spell.schools) do
        if school == wanted then
            return true
        end
    end

    return false
end

-- School-specific mutation enhancers contribute only when a spell has the matching school.
-- Example: a Hexes spell gains the enhancer level; a spell without that school gains zero.
function enhancers.hex(level, _, _, spell)
    if has_school(spell, schools.HEXES) then
        return level
    end

    return 0
end

-- Keep Necromancy's enhancement tied to its school even when the same spell
-- also has another school; the common collector adds the returned level.
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
