-- Ozocubu's Refrigeration (SPELL_OZOCUBUS_REFRIGERATION) is a level 7 spell
-- in ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_OZOCUBUS_REFRIGERATION",
    numeric_id = 56,
    status = "defined",
    name = "Ozocubu's Refrigeration",
    schools = {
        "ice",
    },
    flags = {
        "area",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_OZOCUBUS_REFRIGERATION",
}

register.definition(categories.SPELLS, definition)

return definition
