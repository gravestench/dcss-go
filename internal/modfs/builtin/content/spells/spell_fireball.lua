-- Fireball (SPELL_FIREBALL) is a level 5 spell in conjuration, fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FIREBALL",
    numeric_id = 4,
    status = "defined",
    name = "Fireball",
    schools = {
        "conjuration",
        "fire",
    },
    -- Fireball takes explicit aim. Its source tracer flag is part of the spell
    -- record; the registered effect decides how the blast reaches that point.
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 5,
    power_cap = 200,
    -- Both bounds are five, so cast range does not scale with spell power.
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_FIREBALL",
}

register.definition(categories.SPELLS, definition)

return definition
