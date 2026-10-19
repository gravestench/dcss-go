-- Chaos Breath (SPELL_CHAOS_BREATH) is a level 5 spell in conjuration,
-- random.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CHAOS_BREATH",
    numeric_id = 227,
    status = "defined",
    name = "Chaos Breath",
    schools = {
        "conjuration",
        "random",
    },
    flags = {
        "dir_or_target",
        "monster",
        "noisy",
        "needs_tracer",
        "cloud",
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
