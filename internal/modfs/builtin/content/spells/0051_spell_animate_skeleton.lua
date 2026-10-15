-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:573
-- Enum line: 75

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ANIMATE_SKELETON",
    numeric_id = 50,
    status = "defined",
    name = "Animate Skeleton",
    schools = {
        "necromancy",
    },
    flags = {
        "utility",
        "monster",
    },
    level = 1,
    power_cap = 50,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_ANIMATE_SKELETON",
}

register.definition(categories.SPELLS, definition)

return definition
