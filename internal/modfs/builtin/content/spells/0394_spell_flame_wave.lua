-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3518
-- Enum line: 531

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FLAME_WAVE",
    numeric_id = 393,
    status = "defined",
    name = "Flame Wave",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "area",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "3",
    max_range_expr = "3",
    noise = 0,
    effect_noise = 12,
    tile_id = "TILEG_FLAME_WAVE",
}

register.definition(categories.SPELLS, definition)

return definition
