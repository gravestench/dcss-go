-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3507
-- Enum line: 530

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SCORCH",
    numeric_id = 392,
    status = "defined",
    name = "Scorch",
    schools = {
        "fire",
    },
    flags = {
        "no_ghost",
    },
    level = 2,
    power_cap = 50,
    min_range_expr = "3",
    max_range_expr = "3",
    noise = 4,
    effect_noise = 8,
    tile_id = "TILEG_SCORCH",
}

register.definition(categories.SPELLS, definition)

return definition
