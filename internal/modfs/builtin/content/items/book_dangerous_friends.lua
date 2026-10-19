-- book of Dangerous Friends (BOOK_DANGEROUS_FRIENDS) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_DANGEROUS_FRIENDS",
    name = "book of Dangerous Friends",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 69,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Dangerous Friends has its display text here so identification policy
    -- can choose known or unknown names consistently.
    naming = {
        text = "book of Dangerous Friends",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Dangerous Friends enters
    -- random item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_SUMMON_GUARDIAN_GOLEM,
            spells.SPELL_IOOD,
            spells.SPELL_SPELLFORGED_SERVITOR,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
