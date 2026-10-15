-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:96
-- Enum line: 25

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BOLT_OF_FIRE",
    numeric_id = 10,
    status = "defined",
    name = "Bolt of Fire",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_BOLT_OF_FIRE",
}

register.definition(categories.SPELLS, definition)

return definition
