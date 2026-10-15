-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:661
-- Enum line: 86

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_OZOCUBUS_ARMOUR",
    numeric_id = 59,
    status = "defined",
    name = "Ozocubu's Armour",
    schools = {
        "ice",
    },
    flags = {
        "no_ghost",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_OZOCUBUS_ARMOUR",
}

register.definition(categories.SPELLS, definition)

return definition
