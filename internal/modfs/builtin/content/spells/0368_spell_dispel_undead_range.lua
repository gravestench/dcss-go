-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3297
-- Enum line: 503

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DISPEL_UNDEAD_RANGE",
    numeric_id = 367,
    status = "defined",
    name = "Dispel Undead Range",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 5,
    power_cap = 100,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_DISPEL_UNDEAD",
}

register.definition(categories.SPELLS, definition)

return definition
