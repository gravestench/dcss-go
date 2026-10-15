-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:266
-- Enum line: 41

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MEPHITIC_CLOUD",
    numeric_id = 24,
    status = "defined",
    name = "Mephitic Cloud",
    schools = {
        "conjuration",
        "poison",
        "air",
    },
    flags = {
        "dir_or_target",
        "area",
        "needs_tracer",
        "cloud",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_MEPHITIC_CLOUD",
}

register.definition(categories.SPELLS, definition)

return definition
