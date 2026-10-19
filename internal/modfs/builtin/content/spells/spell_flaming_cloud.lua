-- Flaming Cloud (SPELL_FLAMING_CLOUD) is a level 5 spell in conjuration,
-- fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FLAMING_CLOUD",
    numeric_id = 303,
    status = "defined",
    name = "Flaming Cloud",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "target",
        "area",
        "monster",
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
