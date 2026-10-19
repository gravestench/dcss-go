-- the Unrestrained Analects (BOOK_UNRESTRAINED) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

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
    -- Source: crawl-ref/source/item-name.cc
    -- the Unrestrained Analects has its display text here so identification policy
    -- can choose known or unknown names consistently.
    naming = {
        text = "the Unrestrained Analects",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether the Unrestrained Analects enters
    -- random item pools; held copies remain separate entities.
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
