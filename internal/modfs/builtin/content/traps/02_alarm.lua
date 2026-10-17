-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_ALARM,
    name = "alarm trap",
    glyph = "^",
    source_feature = "DNGN_TRAP_ALARM",
    source_order = 2,
    regular = true,
    effect = "policy.traps.effects.alarm",
}

register.definition(categories.TRAPS, definition)

return definition
