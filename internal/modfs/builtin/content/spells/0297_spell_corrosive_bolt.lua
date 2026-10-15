-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2605
-- Enum line: 414

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CORROSIVE_BOLT",
    numeric_id = 296,
    status = "defined",
    name = "Corrosive Bolt",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_CORROSIVE_BOLT",
}

register.definition(categories.SPELLS, definition)

return definition
