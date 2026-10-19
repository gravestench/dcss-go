-- Zot trap (ids.TRAP_ZOT) maps source feature DNGN_TRAP_ZOT.
-- Placement creates trap state; activation delegates to
-- policy.traps.effects.zot and can update or remove that state.

-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_ZOT,
    name = "Zot trap",
    glyph = "^",
    source_feature = "DNGN_TRAP_ZOT",
    regular = true,
    effect = "policy.traps.effects.zot",
}

register.definition(categories.TRAPS, definition)

return definition
