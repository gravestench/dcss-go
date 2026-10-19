-- Beastly Appendage (SPELL_BEASTLY_APPENDAGE) is a level 1 spell in
-- transmutation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BEASTLY_APPENDAGE",
    numeric_id = 221,
    status = "defined",
    name = "Beastly Appendage",
    schools = {
        "transmutation",
    },
    flags = {
        "helpful",
        "chaotic",
    },
    level = 1,
    power_cap = 50,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_BEASTLY_APPENDAGE",
}

register.definition(categories.SPELLS, definition)

return definition
