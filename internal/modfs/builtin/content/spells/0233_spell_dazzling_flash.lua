-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2077
-- Enum line: 326

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DAZZLING_FLASH",
    numeric_id = 232,
    status = "defined",
    name = "Dazzling Flash",
    schools = {
        "conjuration",
        "hexes",
    },
    flags = {
        "area",
        "no_ghost",
    },
    level = 3,
    power_cap = 50,
    min_range_expr = "2",
    max_range_expr = "3",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_DAZZLING_SPRAY",
}

register.definition(categories.SPELLS, definition)

return definition
