-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:312
-- Enum line: 50

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DEATHS_DOOR",
    numeric_id = 31,
    status = "defined",
    name = "Death's Door",
    schools = {
        "necromancy",
    },
    flags = {
        "utility",
        "no_ghost",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_DEATHS_DOOR",
}

register.definition(categories.SPELLS, definition)

return definition
