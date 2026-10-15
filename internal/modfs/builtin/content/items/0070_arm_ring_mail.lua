-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 96
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 96

local categories = require("constants.catalog")

local definition = {
    id = "ARM_RING_MAIL",
    name = "ring mail",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 2,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:96
    naming = {
        text = "ring mail",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 5,
        ev = -70,
        price = 40,
        acquire_weight = 1000,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_SMALL",
        fit_max_id = "SIZE_MEDIUM",
        mundane = true,
        flags = mod.null,
    },
}

register.definition(categories.ITEMS, definition)

return definition
