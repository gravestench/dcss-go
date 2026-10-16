-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1099

local categories = require("constants.catalog")
local schools = require("constants.spell_schools")
local resistances = require("constants.resistance_ids")

local definition = {
    id = "STAFF_AIR",
    name = "staff of air",
    glyph = 124,
    class = "OBJ_STAVES",
    slot = "weapon",
    class_value = 9,
    subtype_value = 10,
    stackable = false,
    -- Source: crawl-ref/source/melee-attack.cc:2040
    staff = {
        school = schools.AIR,
        skill_id = "SK_AIR_MAGIC",
        resistance_id = resistances.ELECTRICITY,
        message = "The %s is electrocuted!",
    },

    -- Source: crawl-ref/source/item-name.cc:1099
    naming = {
        text = "staff of air",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
