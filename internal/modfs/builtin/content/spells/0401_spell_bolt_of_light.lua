-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2616
-- Enum line: 538

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BOLT_OF_LIGHT",
    numeric_id = 400,
    status = "defined",
    name = "Bolt of Light",
    schools = {
        "conjuration",
        "fire",
        "air",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_LIGHTNING_BOLT",
}

register.definition(categories.SPELLS, definition)

return definition
