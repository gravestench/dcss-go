-- Splinterspray (SPELL_SPLINTERSPRAY) is a level 4 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SPLINTERSPRAY",
    numeric_id = 371,
    status = "defined",
    name = "Splinterspray",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 4,
    power_cap = 0,
    min_range_expr = "3",
    max_range_expr = "3",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_METAL_SPLINTERS",
}

register.definition(categories.SPELLS, definition)

return definition
