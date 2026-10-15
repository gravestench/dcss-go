-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2112
-- Enum line: 331

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_WORD_OF_RECALL",
    numeric_id = 237,
    status = "defined",
    name = "Word of Recall",
    schools = {
        "summoning",
        "translocation",
    },
    flags = {
        "utility",
        "monster",
    },
    level = 3,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_RECALL",
}

register.definition(categories.SPELLS, definition)

return definition
