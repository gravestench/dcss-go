-- Miasma Breath (SPELL_MIASMA_BREATH) is a level 6 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MIASMA_BREATH",
    numeric_id = 153,
    status = "defined",
    name = "Miasma Breath",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "unclean",
        "monster",
        "needs_tracer",
        "cloud",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_MIASMA_BREATH",
}

register.definition(categories.SPELLS, definition)

return definition
