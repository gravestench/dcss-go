-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1094

local categories = require("constants.catalog")
local schools = require("constants.spell_schools")
local resistances = require("constants.resistance_ids")

local definition = {
    id = "STAFF_FIRE",
    name = "staff of fire",
    glyph = 124,
    class = "OBJ_STAVES",
    slot = "weapon",
    class_value = 9,
    subtype_value = 2,
    stackable = false,
    -- Source: crawl-ref/source/melee-attack.cc:2091
    staff = {
        school = schools.FIRE,
        skill_id = "SK_FIRE_MAGIC",
        resistance_id = resistances.FIRE,
        message = "You burn the %s!",
    },

    -- Source: crawl-ref/source/item-name.cc:1094
    naming = {
        text = "staff of fire",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition
