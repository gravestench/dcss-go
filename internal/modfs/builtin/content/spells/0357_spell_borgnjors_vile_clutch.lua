-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3164
-- Enum line: 492

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BORGNJORS_VILE_CLUTCH",
    numeric_id = 356,
    status = "defined",
    name = "Borgnjor's Vile Clutch",
    schools = {
        "necromancy",
        "earth",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 5,
    effect_noise = 4,
    tile_id = "TILEG_BORGNJORS_VILE_CLUTCH",
}

register.definition(categories.SPELLS, definition)

return definition
