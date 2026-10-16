-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1191

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_UNRESTRAINED",
    name = "the Unrestrained Analects",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 72,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1191
    naming = {
        text = "the Unrestrained Analects",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_OLGREBS_TOXIC_RADIANCE,
            spells.SPELL_OZOCUBUS_REFRIGERATION,
            spells.SPELL_IGNITION,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
