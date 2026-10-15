local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local natural_armour = {}

-- Source: player.cc:all_mutation_ac_changes. Values are AC times 100.
function natural_armour.one_two_three(level)
    return level * 100
end

function natural_armour.two_three_four(level)
    return (level + 1) * 100
end

function natural_armour.iridescent(level)
    return level * 200
end

function natural_armour.vulnerability(level)
    return -level * 500
end

registry.add(mutations.MUT_GELATINOUS_BODY, {
    [capabilities.AC_PARTIAL_X100] = natural_armour.one_two_three,
})

registry.add(mutations.MUT_TOUGH_SKIN, {
    [capabilities.AC_PARTIAL_X100] = natural_armour.one_two_three,
})

registry.add(mutations.MUT_SHAGGY_FUR, {
    [capabilities.AC_PARTIAL_X100] = natural_armour.one_two_three,
})

registry.add(mutations.MUT_PHYSICAL_VULNERABILITY, {
    [capabilities.AC_PARTIAL_X100] = natural_armour.vulnerability,
})

registry.add(mutations.MUT_IRIDESCENT_SCALES, {
    [capabilities.AC_FULL_X100] = natural_armour.iridescent,
})

registry.add(mutations.MUT_RUGGED_BROWN_SCALES, {
    [capabilities.AC_FULL_X100] = natural_armour.one_two_three,
})

registry.add(mutations.MUT_ICY_BLUE_SCALES, {
    [capabilities.AC_FULL_X100] = natural_armour.two_three_four,
})

registry.add(mutations.MUT_MOLTEN_SCALES, {
    [capabilities.AC_FULL_X100] = natural_armour.two_three_four,
})

registry.add(mutations.MUT_SLIMY_GREEN_SCALES, {
    [capabilities.AC_FULL_X100] = natural_armour.two_three_four,
})

registry.add(mutations.MUT_THIN_METALLIC_SCALES, {
    [capabilities.AC_FULL_X100] = natural_armour.two_three_four,
})

registry.add(mutations.MUT_YELLOW_SCALES, {
    [capabilities.AC_FULL_X100] = natural_armour.two_three_four,
})

registry.add(mutations.MUT_SHARP_SCALES, {
    [capabilities.AC_FULL_X100] = natural_armour.one_two_three,
})

return natural_armour
