-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2258
-- Enum line: 353

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_WEREBLOOD",
    numeric_id = 253,
    status = "defined",
    name = "Wereblood",
    schools = {
        "transmutation",
    },
    flags = {
        "utility",
        "chaotic",
    },
    level = 2,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 8,
    tile_id = "TILEG_WEREBLOOD",
}

register.definition(categories.SPELLS, definition)

return definition
