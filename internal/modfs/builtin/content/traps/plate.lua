-- pressure plate (ids.TRAP_PLATE) maps source feature DNGN_TRAP_PLATE.
-- Placement creates trap state; activation delegates to
-- policy.traps.effects.plate and can update or remove that state.

-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_PLATE,
    name = "pressure plate",
    glyph = "^",
    source_feature = "DNGN_TRAP_PLATE",
    regular = false,
    effect = "policy.traps.effects.plate",
}

register.definition(categories.TRAPS, definition)

return definition
