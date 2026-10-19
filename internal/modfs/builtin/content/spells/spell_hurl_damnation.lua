-- Hurl Damnation (SPELL_HURL_DAMNATION) is a level 9 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HURL_DAMNATION",
    numeric_id = 73,
    status = "defined",
    name = "Hurl Damnation",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "unholy",
        "needs_tracer",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 9,
    effect_noise = 0,
    tile_id = "TILEG_HURL_DAMNATION",
}

register.definition(categories.SPELLS, definition)

return definition
