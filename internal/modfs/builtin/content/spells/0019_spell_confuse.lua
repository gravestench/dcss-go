-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:198
-- Enum line: 33

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CONFUSE",
    numeric_id = 18,
    status = "defined",
    name = "Confuse",
    schools = {
        "hexes",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "WL_check",
        "monster",
    },
    level = 3,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_CONFUSE",
}

register.definition(categories.SPELLS, definition)

return definition
