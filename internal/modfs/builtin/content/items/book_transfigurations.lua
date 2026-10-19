-- book of Transfigurations (BOOK_TRANSFIGURATIONS) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_TRANSFIGURATIONS",
    name = "book of Transfigurations",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 14,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Transfigurations has its display text here so identification policy
    -- can choose known or unknown names consistently.
    naming = {
        text = "book of Transfigurations",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Transfigurations enters
    -- random item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_IRRADIATE,
            spells.SPELL_BLADE_HANDS,
            spells.SPELL_DRAGON_FORM,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
