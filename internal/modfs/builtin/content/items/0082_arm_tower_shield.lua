-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 155
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 155

local categories = require("constants.catalog")

local definition = {
    id = "ARM_TOWER_SHIELD",
    name = "tower shield",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 14,
    slot = "shield",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:155
    naming = {
        text = "tower shield",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 13,
        ev = -150,
        price = 45,
        acquire_weight = 0,
        slot_id = "EQ_SHIELD",
        fit_min_id = "SIZE_MEDIUM",
        fit_max_id = "SIZE_GIANT",
        mundane = true,
        flags = mod.null,
    },
}

register.definition(categories.ITEMS, definition)

return definition
