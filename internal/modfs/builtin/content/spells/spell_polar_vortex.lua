-- Polar Vortex (SPELL_POLAR_VORTEX) is a level 9 spell in ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_POLAR_VORTEX",
    numeric_id = 208,
    status = "defined",
    name = "Polar Vortex",
    schools = {
        "ice",
    },
    flags = {
        "area",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "POLAR_VORTEX_RADIUS",
    max_range_expr = "POLAR_VORTEX_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_POLAR_VORTEX",
}

register.definition(categories.SPELLS, definition)

return definition
