-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1817
-- Enum line: 260

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_AWAKEN_FOREST",
    numeric_id = 186,
    status = "defined",
    name = "Awaken Forest",
    schools = {
        "hexes",
        "summoning",
    },
    flags = {
        "area",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
