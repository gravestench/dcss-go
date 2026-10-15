-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3153
-- Enum line: 488

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_IGNITION",
    numeric_id = 354,
    status = "defined",
    name = "Ignition",
    schools = {
        "fire",
    },
    flags = {
        "area",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 8,
    effect_noise = 0,
    tile_id = "TILEG_IGNITION",
}

register.definition(categories.SPELLS, definition)

return definition
