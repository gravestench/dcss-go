-- dispersal trap (ids.TRAP_DISPERSAL) maps source feature
-- DNGN_TRAP_DISPERSAL.
-- Placement creates trap state; activation delegates to
-- policy.traps.effects.dispersal and can update or remove that state.

-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_DISPERSAL,
    name = "dispersal trap",
    glyph = "^",
    source_feature = "DNGN_TRAP_DISPERSAL",
    regular = true,
    effect = "policy.traps.effects.dispersal",
}

register.definition(categories.TRAPS, definition)

return definition
