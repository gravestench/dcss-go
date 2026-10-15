-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 638

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "WAND_QUICKSILVER",
    name = "wand of quicksilver",
    glyph = 47,
    class = "OBJ_WANDS",
    class_value = 3,
    subtype_value = 23,
    stackable = false,
    -- Source: crawl-ref/source/spl-book.cc:99
    wand_spell_id = spells.SPELL_QUICKSILVER_BOLT,
    -- Source: crawl-ref/source/item-name.cc:638
    naming = {
        text = "wand of quicksilver",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition
