-- gloves (ARM_GLOVES) belongs to OBJ_ARMOUR and occupies the gloves slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_GLOVES",
    name = "gloves",
    vault_aliases = {
        "pair of gloves",
    },
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 10,
    slot = "gloves",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- gloves has its display text here so identification policy can choose known
    -- or unknown names consistently.
    naming = {
        text = "gloves",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 1,
        ev = 0,
        price = 45,
        acquire_weight = 0,
        slot_id = "EQ_GLOVES",
        fit_min_id = "SIZE_SMALL",
        fit_max_id = "SIZE_MEDIUM",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether gloves enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
