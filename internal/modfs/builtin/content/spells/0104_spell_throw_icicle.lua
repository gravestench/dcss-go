-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:988
-- Enum line: 149

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_THROW_ICICLE",
    numeric_id = 103,
    status = "defined",
    name = "Throw Icicle",
    schools = {
        "conjuration",
        "ice",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_THROW_ICICLE",
}

register.definition(categories.SPELLS, definition)

return definition
