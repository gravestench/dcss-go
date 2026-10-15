-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:494
-- Enum line: 64

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ISKENDERUNS_MYSTIC_BLAST",
    numeric_id = 43,
    status = "defined",
    name = "Iskenderun's Mystic Blast",
    schools = {
        "conjuration",
        "translocation",
    },
    flags = {
        "area",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "2",
    max_range_expr = "2",
    noise = 4,
    effect_noise = 10,
    tile_id = "TILEG_ISKENDERUNS_MYSTIC_BLAST",
}

register.definition(categories.SPELLS, definition)

return definition
