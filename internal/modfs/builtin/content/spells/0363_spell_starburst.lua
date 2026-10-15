-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3230
-- Enum line: 498

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STARBURST",
    numeric_id = 362,
    status = "defined",
    name = "Starburst",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "area",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_STARBURST",
}

register.definition(categories.SPELLS, definition)

return definition
