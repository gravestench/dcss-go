-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1036

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_ALCHEMY",
    name = "book of Alchemy",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 38,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1036
    naming = {
        text = "book of Alchemy",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_SUBLIMATION_OF_BLOOD,
            spells.SPELL_PETRIFY,
            spells.SPELL_IRRADIATE,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
