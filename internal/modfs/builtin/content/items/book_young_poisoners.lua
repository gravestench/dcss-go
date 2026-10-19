-- Young Poisoner's Handbook (BOOK_YOUNG_POISONERS) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_YOUNG_POISONERS",
    name = "Young Poisoner's Handbook",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 9,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- Young Poisoner's Handbook has its display text here so identification policy
    -- can choose known or unknown names consistently.
    naming = {
        text = "Young Poisoner's Handbook",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether Young Poisoner's Handbook enters
    -- random item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_STING,
            spells.SPELL_POISONOUS_VAPOURS,
            spells.SPELL_OLGREBS_TOXIC_RADIANCE,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
