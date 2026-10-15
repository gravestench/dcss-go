-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2404
-- Enum line: 382

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CHAIN_OF_CHAOS",
    numeric_id = 272,
    status = "defined",
    name = "Chain of Chaos",
    schools = {
        "conjuration",
    },
    flags = {
        "area",
        "monster",
        "chaotic",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 8,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
