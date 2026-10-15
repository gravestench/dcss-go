-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:107
-- Enum line: 26

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BOLT_OF_COLD",
    numeric_id = 11,
    status = "defined",
    name = "Bolt of Cold",
    schools = {
        "conjuration",
        "ice",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_BOLT_OF_COLD",
}

register.definition(categories.SPELLS, definition)

return definition
