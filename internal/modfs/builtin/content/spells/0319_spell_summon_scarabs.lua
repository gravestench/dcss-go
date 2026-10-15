-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2899
-- Enum line: 442

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_SCARABS",
    numeric_id = 318,
    status = "defined",
    name = "Summon Scarabs",
    schools = {
        "summoning",
        "necromancy",
    },
    flags = {
        "mons_abjure",
        "monster",
    },
    level = 7,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
