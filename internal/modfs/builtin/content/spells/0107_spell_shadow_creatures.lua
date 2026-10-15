-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1010
-- Enum line: 152

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SHADOW_CREATURES",
    numeric_id = 106,
    status = "defined",
    name = "Shadow Creatures",
    schools = {
        "summoning",
    },
    flags = {
        "mons_abjure",
        "monster",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_SHADOW_CREATURES",
}

register.definition(categories.SPELLS, definition)

return definition
