-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_WEB,
    name = "web",
    glyph = "^",
    source_feature = "DNGN_TRAP_WEB",
    vault_names = {
        "web trap",
    },
    source_order = 8,
    regular = false,
    effect = "policy.traps.effects.web",
}

register.definition(categories.TRAPS, definition)

return definition
