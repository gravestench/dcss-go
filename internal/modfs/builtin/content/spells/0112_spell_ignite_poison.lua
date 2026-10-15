-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1055
-- Enum line: 159

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_IGNITE_POISON",
    numeric_id = 111,
    status = "defined",
    name = "Ignite Poison",
    schools = {
        "fire",
        "transmutation",
        "poison",
    },
    flags = {
        "area",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_IGNITE_POISON",
}

register.definition(categories.SPELLS, definition)

return definition
