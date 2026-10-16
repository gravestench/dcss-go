-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1057

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_WEAPONS",
    name = "book of Weapons",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 65,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1057
    naming = {
        text = "book of Weapons",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_TUKIMAS_DANCE,
            spells.SPELL_PORTAL_PROJECTILE,
            spells.SPELL_BLADE_HANDS,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
