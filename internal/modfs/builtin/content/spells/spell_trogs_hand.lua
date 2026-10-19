-- Trog's Hand (SPELL_TROGS_HAND) is a level 3 spell in none.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_TROGS_HAND",
    numeric_id = 198,
    status = "defined",
    name = "Trog's Hand",
    schools = {
        "none",
    },
    flags = {
        "monster",
        "selfench",
    },
    level = 3,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_TROGS_HAND",
}

register.definition(categories.SPELLS, definition)

return definition
