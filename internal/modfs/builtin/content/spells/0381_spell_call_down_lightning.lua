-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:437
-- Enum line: 516

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CALL_DOWN_LIGHTNING",
    numeric_id = 380,
    status = "defined",
    name = "Call Down Lightning",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "target",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
