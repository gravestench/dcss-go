-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 111
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 111

local categories = require("constants.catalog")

local definition = {
    id = "ARM_TROLL_LEATHER_ARMOUR",
    name = "troll leather armour",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 18,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:111
    naming = {
        text = "troll leather armour",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 4,
        ev = -40,
        price = 150,
        acquire_weight = 50,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = false,
        flags = {
            {
                id = "ARMF_REGENERATION",
                level = 1,
            },
        },
    },
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
