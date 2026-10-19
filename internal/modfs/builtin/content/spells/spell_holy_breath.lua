-- Holy Breath (SPELL_HOLY_BREATH) is a level 5 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HOLY_BREATH",
    numeric_id = 197,
    status = "defined",
    name = "Holy Breath",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "area",
        "needs_tracer",
        "cloud",
        "holy",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 5,
    effect_noise = 2,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
