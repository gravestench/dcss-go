-- scarf (ARM_SCARF) belongs to OBJ_ARMOUR and occupies the cloak slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_SCARF",
    name = "scarf",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 41,
    slot = "cloak",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- scarf has its display text here so identification policy can choose known or
    -- unknown names consistently.
    naming = {
        text = "scarf",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 0,
        ev = 0,
        price = 50,
        acquire_weight = 0,
        slot_id = "EQ_CLOAK",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_LARGE",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether scarf enters random item pools; held
    -- copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
