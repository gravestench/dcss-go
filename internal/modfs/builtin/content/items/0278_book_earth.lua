-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1025

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_EARTH",
    name = "book of the Earth",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 56,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1025
    naming = {
        text = "book of the Earth",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_LEDAS_LIQUEFACTION,
            spells.SPELL_LRD,
            spells.SPELL_STATUE_FORM,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
