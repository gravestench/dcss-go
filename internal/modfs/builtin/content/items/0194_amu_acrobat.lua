-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 776

local categories = require("constants.catalog")
local jewellery_kinds = require("constants.jewellery_kind")
local capabilities = require("constants.jewellery_capabilities")
local magnitudes = require("constants.jewellery_magnitudes")

local definition = {
    id = "AMU_ACROBAT",
    name = "amulet of the acrobat",
    glyph = 34,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 37,
    stackable = false,
    -- Source: crawl-ref/source/item-prop-enum.h:200-266
    jewellery = {
        kind = jewellery_kinds.AMULET,
        -- Source: crawl-ref/source/player-equip.cc:1000-1290
        effects = {
            [capabilities.ACROBAT] = 1,
        },
    },

    -- Source: crawl-ref/source/item-name.cc:776
    naming = {
        text = "amulet of the acrobat",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
