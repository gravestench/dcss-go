-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3075
-- Enum line: 477

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STILL_WINDS",
    numeric_id = 345,
    status = "defined",
    name = "Still Winds",
    schools = {
        "hexes",
        "air",
    },
    flags = {
        "monster",
        "selfench",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
