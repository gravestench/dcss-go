-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1541
-- Enum line: 222

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ACID_SPLASH",
    numeric_id = 158,
    status = "defined",
    name = "Acid Splash",
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
