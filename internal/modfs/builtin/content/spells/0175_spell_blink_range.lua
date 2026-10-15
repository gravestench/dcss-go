-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:459
-- Enum line: 242

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BLINK_RANGE",
    numeric_id = 174,
    status = "defined",
    name = "Blink Range",
    schools = {
        "translocation",
    },
    flags = {
        "escape",
        "monster",
        "selfench",
    },
    level = 2,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_BLINK",
}

register.definition(categories.SPELLS, definition)

return definition
