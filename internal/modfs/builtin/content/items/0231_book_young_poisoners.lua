-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1177

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_YOUNG_POISONERS",
    name = "Young Poisoner's Handbook",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 9,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1177
    naming = {
        text = "Young Poisoner's Handbook",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_STING,
            spells.SPELL_POISONOUS_VAPOURS,
            spells.SPELL_OLGREBS_TOXIC_RADIANCE,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
