-- Great Wizards, Vol. II (BOOK_BIOGRAPHIES_II) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_BIOGRAPHIES_II",
    name = "Great Wizards, Vol. II",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 73,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- Great Wizards, Vol. II has its display text here so identification policy
    -- can choose known or unknown names consistently.
    naming = {
        text = "Great Wizards, Vol. II",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether Great Wizards, Vol. II enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_INTOXICATE,
            spells.SPELL_BORGNJORS_VILE_CLUTCH,
            spells.SPELL_NOXIOUS_BOG,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
