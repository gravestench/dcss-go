-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_TELEPORT,
    name = "teleport trap",
    glyph = "^",
    source_feature = "DNGN_TRAP_TELEPORT",
    source_order = 9,
    regular = false,
    one_shot = true,
    effect = "policy.traps.effects.teleport",
}

register.definition(categories.TRAPS, definition)

return definition
