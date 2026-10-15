-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1495
-- Enum line: 219

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BLINK_OTHER",
    numeric_id = 155,
    status = "defined",
    name = "Blink Other",
    schools = {
        "translocation",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "escape",
        "monster",
        "needs_tracer",
    },
    level = 2,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_BLINK_OTHER",
}

register.definition(categories.SPELLS, definition)

return definition
