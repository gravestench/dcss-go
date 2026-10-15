-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3562
-- Enum line: 55

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_SCORPIONS",
    numeric_id = 36,
    status = "defined",
    name = "Summon Scorpions",
    schools = {
        "summoning",
        "poison",
    },
    flags = {
        "mons_abjure",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_SCORPIONS",
}

register.definition(categories.SPELLS, definition)

return definition
