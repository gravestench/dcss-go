-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1222
-- Enum line: 190

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CHAIN_LIGHTNING",
    numeric_id = 134,
    status = "defined",
    name = "Chain Lightning",
    schools = {
        "air",
        "conjuration",
    },
    flags = {
        "area",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 25,
    effect_noise = 10,
    tile_id = "TILEG_CHAIN_LIGHTNING",
}

register.definition(categories.SPELLS, definition)

return definition
