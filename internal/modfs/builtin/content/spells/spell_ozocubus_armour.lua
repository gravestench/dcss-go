-- Ozocubu's Armour (SPELL_OZOCUBUS_ARMOUR) is a level 3 spell in ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_OZOCUBUS_ARMOUR",
    numeric_id = 59,
    status = "defined",
    name = "Ozocubu's Armour",
    schools = {
        "ice",
    },
    flags = {
        "no_ghost",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_OZOCUBUS_ARMOUR",
}

register.definition(categories.SPELLS, definition)

return definition
