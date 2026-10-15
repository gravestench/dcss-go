-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 89
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 89

local categories = require("constants.catalog")

local definition = {
    id = "ARM_ANIMAL_SKIN",
    name = "animal skin",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 16,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:89
    naming = {
        text = "animal skin",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 2,
        ev = 0,
        price = 3,
        acquire_weight = 333,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = true,
        flags = mod.null,
    },
}

register.definition(categories.ITEMS, definition)

return definition
