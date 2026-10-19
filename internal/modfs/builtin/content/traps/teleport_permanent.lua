-- permanent teleport trap (ids.TRAP_TELEPORT_PERMANENT) maps source feature
-- DNGN_TRAP_TELEPORT_PERMANENT.
-- Placement creates trap state; activation delegates to
-- policy.traps.effects.teleport_permanent and can update or remove that
-- state.

-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_TELEPORT_PERMANENT,
    name = "permanent teleport trap",
    glyph = "^",
    source_feature = "DNGN_TRAP_TELEPORT_PERMANENT",
    regular = true,
    effect = "policy.traps.effects.teleport_permanent",
}

register.definition(categories.TRAPS, definition)

return definition
