-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:73
-- Enum line: 23

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CONJURE_FLAME",
    numeric_id = 8,
    status = "defined",
    name = "Conjure Flame",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "neutral",
        "no_ghost",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 2,
    tile_id = "TILEG_CONJURE_FLAME",
}

register.definition(categories.SPELLS, definition)

return definition
