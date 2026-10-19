-- Orb of Destruction (SPELL_IOOD) is a level 7 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_IOOD",
    numeric_id = 182,
    status = "defined",
    name = "Orb of Destruction",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "8",
    max_range_expr = "8",
    noise = 7,
    effect_noise = 0,
    tile_id = "TILEG_IOOD",
}

register.definition(categories.SPELLS, definition)

return definition
