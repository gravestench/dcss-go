-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1383
-- Enum line: 210

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_HELL_BEAST",
    numeric_id = 146,
    status = "defined",
    name = "Summon Hell Beast",
    schools = {
        "summoning",
    },
    flags = {
        "unholy",
        "monster",
        "selfench",
    },
    level = 4,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_HELL_BEAST",
}

register.definition(categories.SPELLS, definition)

return definition
