-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1484
-- Enum line: 218

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_DRAKES",
    numeric_id = 154,
    status = "defined",
    name = "Summon Drakes",
    schools = {
        "summoning",
        "necromancy",
    },
    flags = {
        "unclean",
        "monster",
        "mons_abjure",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_DRAKES",
}

register.definition(categories.SPELLS, definition)

return definition
