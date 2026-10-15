-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1669
-- Enum line: 235

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HASTE_OTHER",
    numeric_id = 167,
    status = "defined",
    name = "Haste Other",
    schools = {
        "hexes",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "helpful",
        "hasty",
        "needs_tracer",
        "utility",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_HASTE_OTHER",
}

register.definition(categories.SPELLS, definition)

return definition
