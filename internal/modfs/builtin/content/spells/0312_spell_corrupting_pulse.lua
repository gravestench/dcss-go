-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2811
-- Enum line: 435

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CORRUPTING_PULSE",
    numeric_id = 311,
    status = "defined",
    name = "Corrupting Pulse",
    schools = {
        "hexes",
        "transmutation",
    },
    flags = {
        "area",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
