-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:254
-- Enum line: 40

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FREEZING_CLOUD",
    numeric_id = 23,
    status = "defined",
    name = "Freezing Cloud",
    schools = {
        "conjuration",
        "ice",
        "air",
    },
    flags = {
        "target",
        "area",
        "needs_tracer",
        "cloud",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 6,
    effect_noise = 2,
    tile_id = "TILEG_FREEZING_CLOUD",
}

register.definition(categories.SPELLS, definition)

return definition
