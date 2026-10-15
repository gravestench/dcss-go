-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1167
-- Enum line: 178

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_INTOXICATE",
    numeric_id = 126,
    status = "defined",
    name = "Alistair's Intoxication",
    schools = {
        "transmutation",
        "poison",
    },
    flags = {
        "none",
    },
    level = 5,
    power_cap = 150,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_ALISTAIRS_INTOXICATION",
}

register.definition(categories.SPELLS, definition)

return definition
