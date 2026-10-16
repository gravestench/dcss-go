-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1096

local categories = require("constants.catalog")
local schools = require("constants.spell_schools")
local resistances = require("constants.resistance_ids")

local definition = {
    id = "STAFF_POISON",
    name = "staff of poison",
    glyph = 124,
    class = "OBJ_STAVES",
    slot = "weapon",
    class_value = 9,
    subtype_value = 4,
    stackable = false,
    -- Source: crawl-ref/source/melee-attack.cc:2110
    staff = {
        school = schools.POISON,
        skill_id = "SK_POISON_MAGIC",
        resistance_id = resistances.POISON,
        poison_level = 2,
        message = "You envenom the %s!",
    },

    -- Source: crawl-ref/source/item-name.cc:1096
    naming = {
        text = "staff of poison",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition
