-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:683
-- Enum line: 88

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_REPEL_MISSILES",
    numeric_id = 61,
    status = "defined",
    name = "Repel Missiles",
    schools = {
        "air",
    },
    flags = {
        "monster",
    },
    level = 2,
    power_cap = 50,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_REPEL_MISSILES",
}

register.definition(categories.SPELLS, definition)

return definition
