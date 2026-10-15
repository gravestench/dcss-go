-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2471
-- Enum line: 398

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_FOREST",
    numeric_id = 284,
    status = "defined",
    name = "Summon Forest",
    schools = {
        "summoning",
        "translocation",
    },
    flags = {
        "none",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 10,
    tile_id = "TILEG_SUMMON_FOREST",
}

register.definition(categories.SPELLS, definition)

return definition
