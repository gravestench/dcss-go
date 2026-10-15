-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1564
-- Enum line: 223

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FIRE_BREATH",
    numeric_id = 159,
    status = "defined",
    name = "Fire Breath",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "dir_or_target",
        "monster",
        "noisy",
        "needs_tracer",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_FIRE_BREATH",
}

register.definition(categories.SPELLS, definition)

return definition
