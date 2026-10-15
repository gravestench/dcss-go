-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2987
-- Enum line: 465

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_AWAKEN_EARTH",
    numeric_id = 333,
    status = "defined",
    name = "Awaken Earth",
    schools = {
        "summoning",
        "earth",
    },
    flags = {
        "monster",
        "target",
    },
    level = 7,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
