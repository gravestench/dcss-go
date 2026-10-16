-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1100

local categories = require("constants.catalog")
local schools = require("constants.spell_schools")

local definition = {
    id = "STAFF_EARTH",
    name = "staff of earth",
    glyph = 124,
    class = "OBJ_STAVES",
    slot = "weapon",
    class_value = 9,
    subtype_value = 11,
    stackable = false,
    -- Source: crawl-ref/source/melee-attack.cc:2076
    staff = {
        school = schools.EARTH,
        skill_id = "SK_EARTH_MAGIC",
        ac_rolls = 3,
        damage_numerator = 4,
        damage_denominator = 3,
        message = "You shatter the %s!",
    },

    -- Source: crawl-ref/source/item-name.cc:1100
    naming = {
        text = "staff of earth",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition
