local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local armour = {}

function armour.sturdy_frame(level)
    return level * 2
end

function armour.quadrumanous(level)
    return level > 0 and 1 or 0
end

function armour.poor_body_fit(level)
    return level > 0 and 1 or 0
end

registry.add(mutations.MUT_STURDY_FRAME, {
    [capabilities.BODY_ENCUMBRANCE_REDUCTION] = armour.sturdy_frame,
})

registry.add(mutations.MUT_QUADRUMANOUS, {
    [capabilities.QUADRUMANOUS_SHIELDS] = armour.quadrumanous,
})

registry.add(mutations.MUT_DEFORMED, {
    [capabilities.BODY_ARMOUR_AC_PENALTY] = armour.poor_body_fit,
})

registry.add(mutations.MUT_PSEUDOPODS, {
    [capabilities.BODY_ARMOUR_AC_PENALTY] = armour.poor_body_fit,
})

return armour
