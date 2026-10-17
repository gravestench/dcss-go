-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_TELEPORT_PERMANENT,
    name = "permanent teleport trap",
    glyph = "^",
    source_feature = "DNGN_TRAP_TELEPORT_PERMANENT",
    source_order = 1,
    regular = true,
    effect = "policy.traps.effects.teleport_permanent",
}

register.definition(categories.TRAPS, definition)

return definition
