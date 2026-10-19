-- book of Chaos (BOOK_CHAOS) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

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
    -- Source: crawl-ref/source/item-name.cc
    -- book of Chaos has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Chaos",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Chaos enters random item
    -- pools; held copies remain separate entities.
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
