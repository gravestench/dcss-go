-- Pyroclastic Surge (SPELL_PYROCLASTIC_SURGE) is a level 5 spell in
-- conjuration, fire, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_PYROCLASTIC_SURGE",
    numeric_id = 384,
    status = "defined",
    name = "Pyroclastic Surge",
    schools = {
        "conjuration",
        "fire",
        "earth",
    },
    flags = {
        "dir_or_target",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
