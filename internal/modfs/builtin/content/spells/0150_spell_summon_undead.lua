-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1417
-- Enum line: 213

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_UNDEAD",
    numeric_id = 149,
    status = "defined",
    name = "Summon Undead",
    schools = {
        "summoning",
        "necromancy",
    },
    flags = {
        "monster",
        "mons_abjure",
    },
    level = 7,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_UNDEAD",
}

register.definition(categories.SPELLS, definition)

return definition
