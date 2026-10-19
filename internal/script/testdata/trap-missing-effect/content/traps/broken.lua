-- A trap definition without an effect resolver must fail coverage.

local categories = require("constants.catalog")

register.definition(categories.TRAPS, {
    id = "TRAP_TEST_BROKEN",
    name = "broken trap",
    glyph = "^",
    regular = false,
    effect = "policy.traps.effects.not_present",
})
