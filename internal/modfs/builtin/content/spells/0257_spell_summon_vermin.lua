-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2269
-- Enum line: 358

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_VERMIN",
    numeric_id = 256,
    status = "defined",
    name = "Summon Vermin",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
        "unholy",
        "selfench",
        "mons_abjure",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_VERMIN",
}

register.definition(categories.SPELLS, definition)

return definition
