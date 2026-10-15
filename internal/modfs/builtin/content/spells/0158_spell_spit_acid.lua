-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1529
-- Enum line: 221

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SPIT_ACID",
    numeric_id = 157,
    status = "defined",
    name = "Spit Acid",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "monster",
        "noisy",
        "needs_tracer",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_SPIT_ACID",
}

register.definition(categories.SPELLS, definition)

return definition
