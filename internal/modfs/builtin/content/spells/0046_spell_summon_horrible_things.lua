-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:505
-- Enum line: 68

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_HORRIBLE_THINGS",
    numeric_id = 45,
    status = "defined",
    name = "Summon Horrible Things",
    schools = {
        "summoning",
    },
    flags = {
        "unholy",
        "chaotic",
        "mons_abjure",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_HORRIBLE_THINGS",
}

register.definition(categories.SPELLS, definition)

return definition
