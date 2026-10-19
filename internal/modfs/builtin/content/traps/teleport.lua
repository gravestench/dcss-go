-- teleport trap (ids.TRAP_TELEPORT) maps source feature DNGN_TRAP_TELEPORT.
-- Placement creates trap state; activation delegates to
-- policy.traps.effects.teleport and can update or remove that state.

-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_TELEPORT,
    name = "teleport trap",
    glyph = "^",
    source_feature = "DNGN_TRAP_TELEPORT",
    regular = false,
    one_shot = true,
    effect = "policy.traps.effects.teleport",
}

register.definition(categories.TRAPS, definition)

return definition
