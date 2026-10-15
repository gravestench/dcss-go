-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:728
-- Enum line: 99

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BANISHMENT",
    numeric_id = 68,
    status = "defined",
    name = "Banishment",
    schools = {
        "translocation",
    },
    flags = {
        "dir_or_target",
        "unholy",
        "chaotic",
        "monster",
        "needs_tracer",
        "WL_check",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_BANISHMENT",
}

register.definition(categories.SPELLS, definition)

return definition
