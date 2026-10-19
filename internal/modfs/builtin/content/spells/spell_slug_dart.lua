-- Slug Dart (SPELL_SLUG_DART) is a level 1 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SLUG_DART",
    numeric_id = 336,
    status = "defined",
    name = "Slug Dart",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
