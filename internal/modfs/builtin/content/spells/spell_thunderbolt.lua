-- Thunderbolt (SPELL_THUNDERBOLT) is a level 2 spell in conjuration, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_THUNDERBOLT",
    numeric_id = 224,
    status = "defined",
    name = "Thunderbolt",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "dir_or_target",
        "not_self",
    },
    level = 2,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 15,
    effect_noise = 0,
    tile_id = "TILEG_THUNDERBOLT",
}

register.definition(categories.SPELLS, definition)

return definition
