local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local armour = {}

-- Body-shape mutation modifiers are kept together for armour fit and AC calculations.
-- Example: Sturdy Frame level two contributes four, while Poor Body Fit is a presence flag.
function armour.sturdy_frame(level)
    return level * 2
end

-- Treat any Quadrumanous level as an anatomy capability rather than adding
-- extra hands per level in equipment calculations.
function armour.quadrumanous(level)
    return level > 0 and 1 or 0
end

-- Signal body-armour fit loss as a boolean capability so the equipment
-- policy can reject the slot without interpreting mutation text.
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
