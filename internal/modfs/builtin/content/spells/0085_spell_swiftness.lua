-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:842
-- Enum line: 121

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SWIFTNESS",
    numeric_id = 84,
    status = "defined",
    name = "Swiftness",
    schools = {
        "air",
    },
    flags = {
        "hasty",
        "selfench",
        "utility",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SWIFTNESS",
}

register.definition(categories.SPELLS, definition)

return definition
