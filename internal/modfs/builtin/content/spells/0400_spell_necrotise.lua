-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:562
-- Enum line: 537

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_NECROTISE",
    numeric_id = 399,
    status = "defined",
    name = "Necrotise",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "WL_check",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_NECROTISE",
}

register.definition(categories.SPELLS, definition)

return definition
