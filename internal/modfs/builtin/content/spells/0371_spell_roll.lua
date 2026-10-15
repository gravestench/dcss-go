-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3341
-- Enum line: 506

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ROLL",
    numeric_id = 370,
    status = "defined",
    name = "Roll",
    schools = {
        "earth",
    },
    flags = {
        "monster",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
