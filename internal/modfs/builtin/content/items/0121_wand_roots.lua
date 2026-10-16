-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 639

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "WAND_ROOTS",
    name = "wand of roots",
    glyph = 47,
    class = "OBJ_WANDS",
    class_value = 3,
    subtype_value = 24,
    stackable = false,
    -- Source: crawl-ref/source/spl-book.cc:101
    wand_spell_id = spells.SPELL_FASTROOT,
    -- Source: crawl-ref/source/item-name.cc:639
    naming = {
        text = "wand of roots",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
