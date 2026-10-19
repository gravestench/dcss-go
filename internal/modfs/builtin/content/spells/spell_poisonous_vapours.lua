-- Poisonous Vapours (SPELL_POISONOUS_VAPOURS) is a level 2 spell in poison,
-- air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_POISONOUS_VAPOURS",
    numeric_id = 352,
    status = "defined",
    name = "Poisonous Vapours",
    schools = {
        "poison",
        "air",
    },
    -- Vapours asks for a target cell and carries the source not-self guard;
    -- its fixed LOS range does not consume the 50 power cap for distance.
    flags = {
        "target",
        "not_self",
    },
    level = 2,
    power_cap = 50,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_POISONOUS_VAPOURS",
}

register.definition(categories.SPELLS, definition)

return definition
