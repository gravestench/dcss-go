-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1054

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_TUNDRA",
    name = "book of the Tundra",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 63,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1054
    naming = {
        text = "book of the Tundra",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_HAILSTORM,
            spells.SPELL_ICE_FORM,
            spells.SPELL_SIMULACRUM,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
