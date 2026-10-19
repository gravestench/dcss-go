-- Ensorcelled Hibernation (SPELL_HIBERNATION) is a level 2 spell in hexes,
-- ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HIBERNATION",
    numeric_id = 115,
    status = "defined",
    name = "Ensorcelled Hibernation",
    schools = {
        "hexes",
        "ice",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
        "WL_check",
    },
    level = 2,
    power_cap = 56,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_ENSORCELLED_HIBERNATION",
}

register.definition(categories.SPELLS, definition)

return definition
