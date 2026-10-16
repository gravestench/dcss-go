-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1062

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_CHAOS",
    name = "book of Chaos",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 71,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1062
    naming = {
        text = "book of Chaos",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_CONJURE_BALL_LIGHTNING,
            spells.SPELL_DISJUNCTION,
            spells.SPELL_DISCORD,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
