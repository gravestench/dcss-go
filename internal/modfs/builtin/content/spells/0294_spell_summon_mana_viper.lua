-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2571
-- Enum line: 411

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_MANA_VIPER",
    numeric_id = 293,
    status = "defined",
    name = "Summon Mana Viper",
    schools = {
        "summoning",
        "hexes",
    },
    flags = {
        "mons_abjure",
    },
    level = 5,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_MANA_VIPER",
}

register.definition(categories.SPELLS, definition)

return definition
