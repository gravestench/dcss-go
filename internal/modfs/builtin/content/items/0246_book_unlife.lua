-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1020

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_UNLIFE",
    name = "book of Unlife",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 24,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1020
    naming = {
        text = "book of Unlife",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_ANIMATE_DEAD,
            spells.SPELL_BORGNJORS_VILE_CLUTCH,
            spells.SPELL_DEATH_CHANNEL,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
