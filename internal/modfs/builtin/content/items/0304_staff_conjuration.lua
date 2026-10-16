-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1098

local categories = require("constants.catalog")
local schools = require("constants.spell_schools")

local definition = {
    id = "STAFF_CONJURATION",
    name = "staff of conjuration",
    glyph = 124,
    class = "OBJ_STAVES",
    slot = "weapon",
    class_value = 9,
    subtype_value = 7,
    stackable = false,
    -- Source: crawl-ref/source/melee-attack.cc:2144
    staff = {
        school = schools.CONJURATION,
        skill_id = "SK_CONJURATIONS",
        ac_rolls = 1,
        message = "You blast the %s!",
    },

    -- Source: crawl-ref/source/item-name.cc:1098
    naming = {
        text = "staff of conjuration",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition
