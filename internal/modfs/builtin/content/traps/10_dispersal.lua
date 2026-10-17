-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_DISPERSAL,
    name = "dispersal trap",
    glyph = "^",
    source_feature = "DNGN_TRAP_DISPERSAL",
    source_order = 10,
    regular = true,
    effect = "policy.traps.effects.dispersal",
}

register.definition(categories.TRAPS, definition)

return definition
