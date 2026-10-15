-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1771
-- Enum line: 254

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_IOOD",
    numeric_id = 182,
    status = "defined",
    name = "Orb of Destruction",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "8",
    max_range_expr = "8",
    noise = 7,
    effect_noise = 0,
    tile_id = "TILEG_IOOD",
}

register.definition(categories.SPELLS, definition)

return definition
