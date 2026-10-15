-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:118
-- Enum line: 27

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_LIGHTNING_BOLT",
    numeric_id = 12,
    status = "defined",
    name = "Lightning Bolt",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "4",
    max_range_expr = "11",
    noise = 5,
    effect_noise = 25,
    tile_id = "TILEG_LIGHTNING_BOLT",
}

register.definition(categories.SPELLS, definition)

return definition
