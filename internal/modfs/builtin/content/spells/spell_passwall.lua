-- Passwall (SPELL_PASSWALL) is a level 2 spell in transmutation, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_PASSWALL",
    numeric_id = 110,
    status = "defined",
    name = "Passwall",
    schools = {
        "transmutation",
        "earth",
    },
    -- This escape spell targets another cell; `not_self` rules out the caster's
    -- square in the source metadata.
    flags = {
        "target",
        "escape",
        "not_self",
        "utility",
    },
    level = 2,
    power_cap = 120,
    -- The 1..7 range is power-scaled by policy.magic.range using this cap.
    min_range_expr = "1",
    max_range_expr = "7",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_PASSWALL",
}

register.definition(categories.SPELLS, definition)

return definition
