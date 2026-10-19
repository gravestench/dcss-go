-- shaft (ids.TRAP_SHAFT) maps source feature DNGN_TRAP_SHAFT.
-- Placement creates trap state; activation delegates to
-- policy.traps.effects.shaft and can update or remove that state.

-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_SHAFT,
    name = "shaft",
    glyph = "^",
    source_feature = "DNGN_TRAP_SHAFT",
    vault_names = {
        "shaft trap",
    },
    regular = true,
    effect = "policy.traps.effects.shaft",
}

register.definition(categories.TRAPS, definition)

return definition
