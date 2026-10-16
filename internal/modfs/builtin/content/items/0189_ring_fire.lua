-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 769

local categories = require("constants.catalog")
local jewellery_kinds = require("constants.jewellery_kind")
local capabilities = require("constants.jewellery_capabilities")
local magnitudes = require("constants.jewellery_magnitudes")

local definition = {
    id = "RING_FIRE",
    name = "ring of fire",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 21,
    stackable = false,
    -- Source: crawl-ref/source/item-prop-enum.h:200-266
    jewellery = {
        kind = jewellery_kinds.RING,
        -- Source: crawl-ref/source/artefact.cc:346-379
        effects = {
            [capabilities.FIRE_RESISTANCE] = 1,
            [capabilities.COLD_RESISTANCE] = -1,
        },
    },

    -- Source: crawl-ref/source/item-name.cc:769
    naming = {
        text = "ring of fire",
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
