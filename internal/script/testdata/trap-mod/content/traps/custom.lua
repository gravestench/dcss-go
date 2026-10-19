-- The custom echo trap enters the trap catalog with a modded id.

local categories = require("constants.catalog")
local ids = require("ids.custom_traps")

local definition = {
    id = ids.TRAP_TEST_CUSTOM,
    name = "custom echo trap",
    glyph = "^",
    regular = false,
    effect = "policy.traps.effects.custom",
}

register.definition(categories.TRAPS, definition)

return definition
