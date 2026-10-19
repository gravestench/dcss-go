-- robe (ARM_ROBE) belongs to OBJ_ARMOUR and occupies the body slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_ROBE",
    name = "robe",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 0,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- robe has its display text here so identification policy can choose known or
    -- unknown names consistently.
    naming = {
        text = "robe",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 2,
        ev = 0,
        price = 7,
        acquire_weight = 1000,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_LARGE",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether robe enters random item pools; held
    -- copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
