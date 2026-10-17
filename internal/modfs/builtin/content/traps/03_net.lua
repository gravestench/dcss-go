-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_NET,
    name = "net trap",
    glyph = "^",
    source_feature = "DNGN_TRAP_NET",
    source_order = 3,
    regular = true,
    effect = "policy.traps.effects.net",
}

register.definition(categories.TRAPS, definition)

return definition
