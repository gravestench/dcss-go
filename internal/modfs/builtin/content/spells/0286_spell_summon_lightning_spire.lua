-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2482
-- Enum line: 399

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_LIGHTNING_SPIRE",
    numeric_id = 285,
    status = "defined",
    name = "Summon Lightning Spire",
    schools = {
        "summoning",
        "air",
    },
    flags = {
        "none",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_LIGHTNING_SPIRE",
}

register.definition(categories.SPELLS, definition)

return definition
