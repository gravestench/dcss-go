local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local attributes = {}

function attributes.strong_strength(level)
    return 4 * level
end

function attributes.strong_intelligence(level)
    return -level
end

function attributes.strong_dexterity(level)
    return -level
end

function attributes.clever_strength(level)
    return -level
end

function attributes.clever_intelligence(level)
    return 4 * level
end

function attributes.clever_dexterity(level)
    return -level
end

function attributes.agile_strength(level)
    return -level
end

function attributes.agile_intelligence(level)
    return -level
end

function attributes.agile_dexterity(level)
    return 4 * level
end

function attributes.weak_strength(level)
    return -2 * level
end

function attributes.dopey_intelligence(level)
    return -2 * level
end

function attributes.clumsy_dexterity(level)
    return -2 * level
end

function attributes.big_brain_intelligence(level)
    return 2 * level
end

function attributes.thin_skeleton_dexterity(level)
    return 2 * level
end

function attributes.divine(level)
    return level > 0 and 1 or 0
end

registry.add(mutations.MUT_STRONG, {
    [capabilities.STRENGTH] = attributes.strong_strength,
    [capabilities.INTELLIGENCE] = attributes.strong_intelligence,
    [capabilities.DEXTERITY] = attributes.strong_dexterity,
})

registry.add(mutations.MUT_CLEVER, {
    [capabilities.STRENGTH] = attributes.clever_strength,
    [capabilities.INTELLIGENCE] = attributes.clever_intelligence,
    [capabilities.DEXTERITY] = attributes.clever_dexterity,
})

registry.add(mutations.MUT_AGILE, {
    [capabilities.STRENGTH] = attributes.agile_strength,
    [capabilities.INTELLIGENCE] = attributes.agile_intelligence,
    [capabilities.DEXTERITY] = attributes.agile_dexterity,
})

registry.add(mutations.MUT_WEAK, {
    [capabilities.STRENGTH] = attributes.weak_strength,
})

registry.add(mutations.MUT_DOPEY, {
    [capabilities.INTELLIGENCE] = attributes.dopey_intelligence,
})

registry.add(mutations.MUT_CLUMSY, {
    [capabilities.DEXTERITY] = attributes.clumsy_dexterity,
})

registry.add(mutations.MUT_BIG_BRAIN, {
    [capabilities.INTELLIGENCE] = attributes.big_brain_intelligence,
})

registry.add(mutations.MUT_THIN_SKELETAL_STRUCTURE, {
    [capabilities.DEXTERITY] = attributes.thin_skeleton_dexterity,
})

registry.add(mutations.MUT_DIVINE_ATTRS, {
    [capabilities.DIVINE_ATTRIBUTES] = attributes.divine,
})

return attributes
