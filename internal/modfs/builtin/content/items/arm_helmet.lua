-- helmet (ARM_HELMET) belongs to OBJ_ARMOUR and occupies the head slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_HELMET",
    name = "helmet",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 9,
    slot = "head",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- helmet has its display text here so identification policy can choose known
    -- or unknown names consistently.
    naming = {
        text = "helmet",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 1,
        ev = 0,
        price = 45,
        acquire_weight = 0,
        slot_id = "EQ_HELMET",
        fit_min_id = "SIZE_SMALL",
        fit_max_id = "SIZE_MEDIUM",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether helmet enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
