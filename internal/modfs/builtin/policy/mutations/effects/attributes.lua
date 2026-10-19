local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local attributes = {}

-- Attribute mutations return modifiers for each stat rather than editing base attributes.
-- Example: Strong level one contributes +4 Strength, -1 Intelligence, and -1 Dexterity.
function attributes.strong_strength(level)
    return 4 * level
end

-- Strong trades one Intelligence per level for its larger Strength gain.
function attributes.strong_intelligence(level)
    return -level
end

-- Strong applies the same one-point tradeoff to Dexterity.
function attributes.strong_dexterity(level)
    return -level
end

-- Clever pays one Strength per level to fund its Intelligence bonus.
function attributes.clever_strength(level)
    return -level
end

-- Clever's primary stat receives four points per mutation level.
function attributes.clever_intelligence(level)
    return 4 * level
end

-- Dexterity joins Strength as Clever's cost.
function attributes.clever_dexterity(level)
    return -level
end

-- Agile's Strength penalty offsets its larger Dexterity gain.
function attributes.agile_strength(level)
    return -level
end

-- Agile also reduces Intelligence once per level.
function attributes.agile_intelligence(level)
    return -level
end

-- Agile grants four Dexterity points per level before other modifiers are summed.
function attributes.agile_dexterity(level)
    return 4 * level
end

-- Weak has no compensating gain and costs two Strength per level.
function attributes.weak_strength(level)
    return -2 * level
end

-- Dopey contributes a two-point Intelligence loss per level.
function attributes.dopey_intelligence(level)
    return -2 * level
end

-- Clumsy contributes a two-point Dexterity loss per level.
function attributes.clumsy_dexterity(level)
    return -2 * level
end

-- Big Brain adds two Intelligence per level without changing base stats.
function attributes.big_brain_intelligence(level)
    return 2 * level
end

-- Thin Skeleton adds two Dexterity per level through the capability sum.
function attributes.thin_skeleton_dexterity(level)
    return 2 * level
end

-- Divine Attributes is a presence flag; higher mutation levels do not stack it.
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
