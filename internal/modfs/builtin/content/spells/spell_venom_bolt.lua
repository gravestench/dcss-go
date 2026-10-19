-- Venom Bolt (SPELL_VENOM_BOLT) is a level 5 spell in conjuration, poison.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_VENOM_BOLT",
    numeric_id = 26,
    status = "defined",
    name = "Venom Bolt",
    schools = {
        "conjuration",
        "poison",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_VENOM_BOLT",
}

register.definition(categories.SPELLS, definition)

return definition
