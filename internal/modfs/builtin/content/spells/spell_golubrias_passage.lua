-- Passage of Golubria (SPELL_GOLUBRIAS_PASSAGE) is a level 4 spell in
-- translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_GOLUBRIAS_PASSAGE",
    numeric_id = 139,
    status = "defined",
    name = "Passage of Golubria",
    schools = {
        "translocation",
    },
    -- The target flag makes input collect a destination; neutral and escape
    -- preserve source classification for the passage effect.
    flags = {
        "target",
        "neutral",
        "escape",
        "selfench",
    },
    level = 4,
    power_cap = 100,
    -- Passage starts at two cells and can extend to line of sight with power.
    min_range_expr = "2",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 8,
    tile_id = "TILEG_PASSAGE_OF_GOLUBRIA",
}

register.definition(categories.SPELLS, definition)

return definition
