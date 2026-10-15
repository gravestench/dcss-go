-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:345
-- Enum line: 53

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_SMALL_MAMMAL",
    numeric_id = 34,
    status = "defined",
    name = "Summon Small Mammal",
    schools = {
        "summoning",
    },
    flags = {
        "none",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_SMALL_MAMMAL",
}

register.definition(categories.SPELLS, definition)

return definition
