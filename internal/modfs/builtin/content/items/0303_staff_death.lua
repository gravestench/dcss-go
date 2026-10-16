-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1097

local categories = require("constants.catalog")
local schools = require("constants.spell_schools")
local resistances = require("constants.resistance_ids")

local definition = {
    id = "STAFF_DEATH",
    name = "staff of death",
    glyph = 124,
    class = "OBJ_STAVES",
    slot = "weapon",
    class_value = 9,
    subtype_value = 6,
    stackable = false,
    -- Source: crawl-ref/source/melee-attack.cc:2127
    staff = {
        school = schools.NECROMANCY,
        skill_id = "SK_NECROMANCY",
        resistance_id = resistances.NEGATIVE_ENERGY,
        negative_energy = true,
        message = "The %s writhes in agony!",
    },

    -- Source: crawl-ref/source/item-name.cc:1097
    naming = {
        text = "staff of death",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition
