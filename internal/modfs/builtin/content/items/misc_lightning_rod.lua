-- lightning rod (MISC_LIGHTNING_ROD) belongs to OBJ_MISCELLANY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "MISC_LIGHTNING_ROD",
    name = "lightning rod",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 9,
    stackable = false,
    -- XP recharge is shared by every carried copy of this subtype.
    evoker = {
        charge_debt = 3,
        max_charges = 4,
        aimed = true,
    },
    -- Source: crawl-ref/source/item-name.cc
    -- lightning rod has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "lightning rod",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether lightning rod enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
