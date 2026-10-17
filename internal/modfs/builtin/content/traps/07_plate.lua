-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_PLATE,
    name = "pressure plate",
    glyph = "^",
    source_feature = "DNGN_TRAP_PLATE",
    source_order = 7,
    regular = false,
    effect = "policy.traps.effects.plate",
}

register.definition(categories.TRAPS, definition)

return definition
