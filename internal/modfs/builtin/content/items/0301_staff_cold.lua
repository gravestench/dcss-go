-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1095

local categories = require("constants.catalog")
local schools = require("constants.spell_schools")
local resistances = require("constants.resistance_ids")

local definition = {
    id = "STAFF_COLD",
    name = "staff of cold",
    glyph = 124,
    class = "OBJ_STAVES",
    slot = "weapon",
    class_value = 9,
    subtype_value = 3,
    stackable = false,
    -- Source: crawl-ref/source/melee-attack.cc:2057
    staff = {
        school = schools.ICE,
        skill_id = "SK_ICE_MAGIC",
        resistance_id = resistances.COLD,
        message = "You freeze the %s!",
    },

    -- Source: crawl-ref/source/item-name.cc:1095
    naming = {
        text = "staff of cold",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition
