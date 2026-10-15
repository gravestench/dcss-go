-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1077
-- Enum line: 164

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_DRAGON",
    numeric_id = 114,
    status = "defined",
    name = "Summon Dragon",
    schools = {
        "summoning",
    },
    flags = {
        "mons_abjure",
        "monster",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 7,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_DRAGON",
}

register.definition(categories.SPELLS, definition)

return definition
