-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1805
-- Enum line: 329

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MIGHT_OTHER",
    numeric_id = 235,
    status = "defined",
    name = "Might Other",
    schools = {
        "hexes",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "helpful",
        "needs_tracer",
        "utility",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_MIGHT",
}

register.definition(categories.SPELLS, definition)

return definition
