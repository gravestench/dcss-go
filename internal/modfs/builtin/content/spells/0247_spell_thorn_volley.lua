-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2202
-- Enum line: 342

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_THORN_VOLLEY",
    numeric_id = 246,
    status = "defined",
    name = "Volley of Thorns",
    schools = {
        "conjuration",
        "earth",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
