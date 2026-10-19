-- wand of roots (WAND_ROOTS) belongs to OBJ_WANDS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "WAND_ROOTS",
    name = "wand of roots",
    glyph = 47,
    class = "OBJ_WANDS",
    class_value = 3,
    subtype_value = 24,
    stackable = false,
    -- Source: crawl-ref/source/spl-book.cc
    wand_spell_id = spells.SPELL_FASTROOT,
    -- Source: crawl-ref/source/item-name.cc
    -- wand of roots has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "wand of roots",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether wand of roots enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
