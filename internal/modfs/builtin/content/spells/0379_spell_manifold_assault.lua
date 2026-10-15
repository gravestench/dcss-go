-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3396
-- Enum line: 514

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MANIFOLD_ASSAULT",
    numeric_id = 378,
    status = "defined",
    name = "Manifold Assault",
    schools = {
        "translocation",
    },
    flags = {
        "no_ghost",
    },
    level = 5,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_MANIFOLD_ASSAULT",
}

register.definition(categories.SPELLS, definition)

return definition
