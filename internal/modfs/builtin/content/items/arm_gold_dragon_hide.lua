-- removed gold dragon hide (ARM_GOLD_DRAGON_HIDE) belongs to OBJ_ARMOUR and
-- occupies the body slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_GOLD_DRAGON_HIDE",
    name = "removed gold dragon hide",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 29,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- removed gold dragon hide has its display text here so identification policy
    -- can choose known or unknown names consistently.
    naming = {
        text = "removed gold dragon hide",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 0,
        ev = 0,
        price = 0,
        acquire_weight = 0,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = false,
        flags = {
            {
                id = "ARMF_RES_COLD",
                level = 1,
            },
            {
                id = "ARMF_RES_FIRE",
                level = 1,
            },
            {
                id = "ARMF_RES_POISON",
                level = 1,
            },
        },
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- The "removed" name is legacy catalog text, not the removed flag.
    -- Forced mode keeps this subtype out of ordinary random item rolls.
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition
