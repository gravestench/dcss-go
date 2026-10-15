-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2054
-- Enum line: 317

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_MINOR_DEMON",
    numeric_id = 225,
    status = "defined",
    name = "Summon Minor Demon",
    schools = {
        "summoning",
    },
    flags = {
        "unholy",
        "selfench",
        "monster",
    },
    level = 2,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_MINOR_DEMON",
}

register.definition(categories.SPELLS, definition)

return definition
