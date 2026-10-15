-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:740
-- Enum line: 103

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STING",
    numeric_id = 70,
    status = "defined",
    name = "Sting",
    schools = {
        "transmutation",
        "poison",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "3",
    max_range_expr = "3",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_STING",
}

register.definition(categories.SPELLS, definition)

return definition
