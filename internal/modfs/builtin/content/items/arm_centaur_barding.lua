-- centaur barding (ARM_CENTAUR_BARDING) belongs to OBJ_ARMOUR and occupies
-- the boots slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_CENTAUR_BARDING",
    name = "centaur barding",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 35,
    slot = "boots",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- centaur barding has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "centaur barding",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 4,
        ev = -60,
        price = 230,
        acquire_weight = 0,
        slot_id = "EQ_BOOTS",
        fit_min_id = "SIZE_MEDIUM",
        fit_max_id = "SIZE_LARGE",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode forced controls whether centaur barding enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition
