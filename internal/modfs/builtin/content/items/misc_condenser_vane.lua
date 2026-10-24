-- condenser vane (MISC_CONDENSER_VANE) belongs to OBJ_MISCELLANY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "MISC_CONDENSER_VANE",
    name = "condenser vane",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 28,
    stackable = false,
    -- XP recharge is shared by every carried copy of this subtype.
    evoker = {
        charge_debt = 10,
        max_charges = 1,
        aimed = false,
    },
    -- Source: crawl-ref/source/item-name.cc
    -- condenser vane has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "condenser vane",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether condenser vane enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
