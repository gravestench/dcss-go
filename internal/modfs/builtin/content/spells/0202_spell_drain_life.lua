-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1931
-- Enum line: 281

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DRAIN_LIFE",
    numeric_id = 201,
    status = "defined",
    name = "Drain Life",
    schools = {
        "necromancy",
    },
    flags = {
        "area",
        "monster",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_DRAIN_LIFE",
}

register.definition(categories.SPELLS, definition)

return definition
