-- Spit Lava (SPELL_SPIT_LAVA) is a level 5 spell in conjuration, fire, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SPIT_LAVA",
    numeric_id = 301,
    status = "defined",
    name = "Spit Lava",
    schools = {
        "conjuration",
        "fire",
        "earth",
    },
    flags = {
        "dir_or_target",
        "monster",
        "noisy",
        "needs_tracer",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
