-- Great Wizards, Vol. VII (BOOK_BIOGRAPHIES_VII) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_BIOGRAPHIES_VII",
    name = "Great Wizards, Vol. VII",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 74,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- Great Wizards, Vol. VII has its display text here so identification policy
    -- can choose known or unknown names consistently.
    naming = {
        text = "Great Wizards, Vol. VII",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether Great Wizards, Vol. VII enters
    -- random item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_TUKIMAS_DANCE,
            spells.SPELL_GOLUBRIAS_PASSAGE,
            spells.SPELL_VIOLENT_UNRAVELLING,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
