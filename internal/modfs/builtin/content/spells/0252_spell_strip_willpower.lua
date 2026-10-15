-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2246
-- Enum line: 349

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STRIP_WILLPOWER",
    numeric_id = 251,
    status = "defined",
    name = "Strip Willpower",
    schools = {
        "hexes",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "WL_check",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_STRIP_WILLPOWER",
}

register.definition(categories.SPELLS, definition)

return definition
