-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:694
-- Enum line: 89

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BERSERKER_RAGE",
    numeric_id = 62,
    status = "defined",
    name = "Berserker Rage",
    schools = {
        "earth",
    },
    flags = {
        "hasty",
        "monster",
    },
    level = 3,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_BERSERKER_RAGE",
}

register.definition(categories.SPELLS, definition)

return definition
