-- hat (ARM_HAT) belongs to OBJ_ARMOUR and occupies the head slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_HAT",
    name = "hat",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 8,
    slot = "head",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- hat has its display text here so identification policy can choose known or
    -- unknown names consistently.
    naming = {
        text = "hat",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 0,
        ev = 0,
        price = 40,
        acquire_weight = 0,
        slot_id = "EQ_HELMET",
        fit_min_id = "SIZE_TINY",
        fit_max_id = "SIZE_LARGE",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether hat enters random item pools; held
    -- copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
