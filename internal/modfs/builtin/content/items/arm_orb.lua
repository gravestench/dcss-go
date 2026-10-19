-- orb (ARM_ORB) belongs to OBJ_ARMOUR and occupies the shield slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_ORB",
    name = "orb",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 42,
    slot = "shield",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- orb has its display text here so identification policy can choose known or
    -- unknown names consistently.
    naming = {
        text = "orb",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 0,
        ev = 0,
        price = 90,
        acquire_weight = 0,
        slot_id = "EQ_SHIELD",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether orb enters random item pools; held
    -- copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
