-- tower shield (ARM_TOWER_SHIELD) belongs to OBJ_ARMOUR and occupies the
-- shield slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_TOWER_SHIELD",
    name = "tower shield",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 14,
    slot = "shield",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- tower shield has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "tower shield",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 13,
        ev = -150,
        price = 45,
        acquire_weight = 0,
        slot_id = "EQ_SHIELD",
        fit_min_id = "SIZE_MEDIUM",
        fit_max_id = "SIZE_GIANT",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether tower shield enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
