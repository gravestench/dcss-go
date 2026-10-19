-- net trap (ids.TRAP_NET) maps source feature DNGN_TRAP_NET.
-- Placement creates trap state; activation delegates to
-- policy.traps.effects.net and can update or remove that state.

-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_NET,
    name = "net trap",
    glyph = "^",
    source_feature = "DNGN_TRAP_NET",
    regular = true,
    effect = "policy.traps.effects.net",
}

register.definition(categories.TRAPS, definition)

return definition
