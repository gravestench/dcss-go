-- Ensnare (SPELL_ENSNARE) is a level 6 spell in conjuration, hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ENSNARE",
    numeric_id = 223,
    status = "defined",
    name = "Ensnare",
    schools = {
        "conjuration",
        "hexes",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
