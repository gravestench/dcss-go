-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:786
-- Enum line: 111

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_GREATER_DEMON",
    numeric_id = 76,
    status = "defined",
    name = "Summon Greater Demon",
    schools = {
        "summoning",
    },
    flags = {
        "unholy",
        "selfench",
        "mons_abjure",
        "monster",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_GREATER_DEMON",
}

register.definition(categories.SPELLS, definition)

return definition
