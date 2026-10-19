-- Searing Breath (SPELL_SEARING_BREATH) is a level 5 spell in conjuration,
-- fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SEARING_BREATH",
    numeric_id = 320,
    status = "defined",
    name = "Searing Breath",
    schools = {
        "conjuration",
        "fire",
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
    tile_id = "TILEG_FIRE_BREATH",
}

register.definition(categories.SPELLS, definition)

return definition
