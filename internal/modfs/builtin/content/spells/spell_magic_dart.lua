-- Magic Dart (SPELL_MAGIC_DART) is a level 1 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MAGIC_DART",
    numeric_id = 3,
    status = "defined",
    name = "Magic Dart",
    schools = {
        "conjuration",
    },
    -- Player spell input asks for a direction or target; the tracer tag is
    -- retained from spl-data.h for consumers that inspect projectile metadata.
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 1,
    -- The low spell cap limits this level-one bolt; range is already fixed at LOS.
    power_cap = 25,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_MAGIC_DART",
}

register.definition(categories.SPELLS, definition)

return definition
