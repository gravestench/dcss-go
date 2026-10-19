-- alarm trap (ids.TRAP_ALARM) maps source feature DNGN_TRAP_ALARM.
-- Placement creates trap state; activation delegates to
-- policy.traps.effects.alarm and can update or remove that state.

-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_ALARM,
    name = "alarm trap",
    glyph = "^",
    source_feature = "DNGN_TRAP_ALARM",
    regular = true,
    effect = "policy.traps.effects.alarm",
}

register.definition(categories.TRAPS, definition)

return definition
