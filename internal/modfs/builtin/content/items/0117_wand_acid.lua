-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 635

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "WAND_ACID",
    name = "wand of acid",
    glyph = 47,
    class = "OBJ_WANDS",
    class_value = 3,
    subtype_value = 17,
    stackable = false,
    -- Source: crawl-ref/source/spl-book.cc:97
    wand_spell_id = spells.SPELL_CORROSIVE_BOLT,
    -- Source: crawl-ref/source/item-name.cc:635
    naming = {
        text = "wand of acid",
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
