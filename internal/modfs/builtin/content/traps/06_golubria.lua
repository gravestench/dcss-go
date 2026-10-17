-- Source: crawl-ref/source/trap-type.h and describe.cc:trap_names.
local categories = require("constants.catalog")
local ids = require("ids.traps")

local definition = {
    id = ids.TRAP_GOLUBRIA,
    name = "passage of Golubria",
    glyph = "^",
    source_feature = "DNGN_PASSAGE_OF_GOLUBRIA",
    source_order = 6,
    regular = false,
    lifetime_turns = {
        minimum = 30,
        random = 20,
    },
    effect = "policy.traps.effects.golubria",
}

register.definition(categories.TRAPS, definition)

return definition
