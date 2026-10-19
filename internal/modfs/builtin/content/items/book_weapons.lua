-- book of Weapons (BOOK_WEAPONS) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_WEAPONS",
    name = "book of Weapons",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 65,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Weapons has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of Weapons",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Weapons enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_TUKIMAS_DANCE,
            spells.SPELL_PORTAL_PROJECTILE,
            spells.SPELL_BLADE_HANDS,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
