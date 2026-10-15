-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1088
-- Enum line: 165

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HIBERNATION",
    numeric_id = 115,
    status = "defined",
    name = "Ensorcelled Hibernation",
    schools = {
        "hexes",
        "ice",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
        "WL_check",
    },
    level = 2,
    power_cap = 56,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_ENSORCELLED_HIBERNATION",
}

register.definition(categories.SPELLS, definition)

return definition
