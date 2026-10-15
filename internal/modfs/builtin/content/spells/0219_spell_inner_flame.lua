-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1999
-- Enum line: 306

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_INNER_FLAME",
    numeric_id = 218,
    status = "defined",
    name = "Inner Flame",
    schools = {
        "hexes",
        "fire",
    },
    flags = {
        "target",
        "not_self",
        "WL_check",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_INNER_FLAME",
}

register.definition(categories.SPELLS, definition)

return definition
