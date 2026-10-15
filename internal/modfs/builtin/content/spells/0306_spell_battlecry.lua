-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2745
-- Enum line: 427

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BATTLECRY",
    numeric_id = 305,
    status = "defined",
    name = "Battlecry",
    schools = {
        "hexes",
    },
    flags = {
        "area",
        "monster",
        "selfench",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
