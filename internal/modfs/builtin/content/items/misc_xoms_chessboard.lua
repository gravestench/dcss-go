-- piece from Xom's chessboard (MISC_XOMS_CHESSBOARD) belongs to
-- OBJ_MISCELLANY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "MISC_XOMS_CHESSBOARD",
    name = "piece from Xom's chessboard",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 26,
    stackable = false,
    -- XP recharge is shared by every carried copy of this subtype.
    evoker = {
        charge_debt = 2,
        max_charges = 15,
        aimed = false,
    },
    -- Source: crawl-ref/source/item-name.cc
    -- piece from Xom's chessboard has its display text here so identification
    -- policy can choose known or unknown names consistently.
    naming = {
        text = "piece from Xom's chessboard",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether piece from Xom's chessboard enters
    -- random item pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
