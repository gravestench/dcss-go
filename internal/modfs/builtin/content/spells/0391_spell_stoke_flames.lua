-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3485
-- Enum line: 528

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STOKE_FLAMES",
    numeric_id = 390,
    status = "defined",
    name = "Stoke Flames",
    schools = {
        "fire",
        "conjuration",
    },
    flags = {
        "monster",
    },
    level = 8,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
