-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1861
-- Enum line: 265

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_SPECTRAL_ORCS",
    numeric_id = 189,
    status = "defined",
    name = "Summon Spectral Orcs",
    schools = {
        "necromancy",
        "summoning",
    },
    flags = {
        "monster",
        "target",
    },
    level = 4,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_SPECTRAL_ORCS",
}

register.definition(categories.SPELLS, definition)

return definition
