-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 995

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_FROST",
    name = "book of Frost",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 3,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:995
    naming = {
        text = "book of Frost",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_FREEZE,
            spells.SPELL_FROZEN_RAMPARTS,
            spells.SPELL_HAILSTORM,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
