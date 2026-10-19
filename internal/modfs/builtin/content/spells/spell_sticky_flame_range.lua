-- Sticky Flame Range (SPELL_STICKY_FLAME_RANGE) is a level 4 spell in
-- conjuration, fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STICKY_FLAME_RANGE",
    numeric_id = 209,
    status = "defined",
    name = "Sticky Flame Range",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_STICKY_FLAME_RANGE",
}

register.definition(categories.SPELLS, definition)

return definition
