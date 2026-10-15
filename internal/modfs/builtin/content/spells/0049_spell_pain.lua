-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:550
-- Enum line: 71

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_PAIN",
    numeric_id = 48,
    status = "defined",
    name = "Pain",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "WL_check",
        "monster",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_PAIN",
}

register.definition(categories.SPELLS, definition)

return definition
