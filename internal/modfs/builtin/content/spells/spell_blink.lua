-- Blink (SPELL_BLINK) is a level 2 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BLINK",
    numeric_id = 42,
    status = "defined",
    name = "Blink",
    schools = {
        "translocation",
    },
    -- No targeting flag is set: Blink chooses its destination in the effect
    -- rather than asking the spell input route for a direction.
    flags = {
        "escape",
        "selfench",
        "utility",
    },
    level = 2,
    power_cap = 50,
    -- -1 is the non-ranged sentinel returned by policy.magic.range.
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_BLINK",
}

register.definition(categories.SPELLS, definition)

return definition
