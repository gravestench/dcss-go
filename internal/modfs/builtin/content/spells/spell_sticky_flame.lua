-- Sticky Flame (SPELL_STICKY_FLAME) is a level 4 spell in conjuration, fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STICKY_FLAME",
    numeric_id = 57,
    status = "defined",
    name = "Sticky Flame",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "1",
    max_range_expr = "1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_STICKY_FLAME",
}

register.definition(categories.SPELLS, definition)

return definition
