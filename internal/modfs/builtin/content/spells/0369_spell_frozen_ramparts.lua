-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3308
-- Enum line: 504

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FROZEN_RAMPARTS",
    numeric_id = 368,
    status = "defined",
    name = "Frozen Ramparts",
    schools = {
        "ice",
    },
    flags = {
        "area",
        "no_ghost",
    },
    level = 3,
    power_cap = 50,
    min_range_expr = "2",
    max_range_expr = "2",
    noise = 3,
    effect_noise = 8,
    tile_id = "TILEG_FROZEN_RAMPARTS",
}

register.definition(categories.SPELLS, definition)

return definition
