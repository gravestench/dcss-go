-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1045

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_DECAY",
    name = "book of Decay",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 52,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1045
    naming = {
        text = "book of Decay",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_CORPSE_ROT,
            spells.SPELL_DISPEL_UNDEAD,
            spells.SPELL_DEATH_CHANNEL,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
