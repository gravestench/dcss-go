-- Dispersal (SPELL_DISPERSAL) is a level 6 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DISPERSAL",
    numeric_id = 123,
    status = "defined",
    name = "Dispersal",
    schools = {
        "translocation",
    },
    -- Dispersal is classified as an area escape, so the spell menu does not
    -- request directional aim from these flags.
    flags = {
        "area",
        "escape",
    },
    level = 6,
    power_cap = 200,
    -- The radius represented by 1..4 grows with spell power in range policy.
    min_range_expr = "1",
    max_range_expr = "4",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_DISPERSAL",
}

register.definition(categories.SPELLS, definition)

return definition
