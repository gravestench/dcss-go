-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3584
-- Enum line: 7

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_NO_SPELL",
    numeric_id = 0,
    status = "sentinel",
    name = "nonexistent spell",
    schools = {
        "none",
    },
    flags = {
        "testing",
    },
    level = 1,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_ERROR",
}

register.definition(categories.SPELLS, definition)

return definition
