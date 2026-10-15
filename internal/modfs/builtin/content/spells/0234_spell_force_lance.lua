-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2088
-- Enum line: 327

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FORCE_LANCE",
    numeric_id = 233,
    status = "defined",
    name = "Force Lance",
    schools = {
        "conjuration",
        "translocation",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "3",
    max_range_expr = "3",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_FORCE_LANCE",
}

register.definition(categories.SPELLS, definition)

return definition
