-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_ZOT,
    name = "Zot trap",
    glyph = "^",
    source_feature = "DNGN_TRAP_ZOT",
    source_order = 4,
    regular = true,
    effect = "policy.traps.effects.zot",
}

register.definition(categories.TRAPS, definition)

return definition
