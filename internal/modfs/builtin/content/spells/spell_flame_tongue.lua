-- Flame Tongue (SPELL_FLAME_TONGUE) is a level 1 spell in conjuration, fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FLAME_TONGUE",
    numeric_id = 109,
    status = "defined",
    name = "Flame Tongue",
    schools = {
        "conjuration",
        "fire",
    },
    -- The source profile permits directional aim and excludes self-targeting;
    -- `monster` records the monster-spell role alongside player-facing metadata.
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
        "monster",
    },
    level = 1,
    power_cap = 40,
    -- Its short 2..5 reach grows with spell power up to this record's cap.
    min_range_expr = "2",
    max_range_expr = "5",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_FLAME_TONGUE",
}

register.definition(categories.SPELLS, definition)

return definition
