-- Spectral Cloud (SPELL_SPECTRAL_CLOUD) is a level 5 spell in conjuration,
-- necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SPECTRAL_CLOUD",
    numeric_id = 239,
    status = "defined",
    name = "Spectral Cloud",
    schools = {
        "conjuration",
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "monster",
        "cloud",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_SPECTRAL_CLOUD",
}

register.definition(categories.SPELLS, definition)

return definition
