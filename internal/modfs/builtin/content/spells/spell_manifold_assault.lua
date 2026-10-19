-- Manifold Assault (SPELL_MANIFOLD_ASSAULT) is a level 5 spell in
-- translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

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
