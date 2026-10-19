-- ring of slaying (RING_SLAYING) belongs to OBJ_JEWELLERY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local jewellery_kinds = require("constants.jewellery_kind")
local capabilities = require("constants.jewellery_capabilities")
local magnitudes = require("constants.jewellery_magnitudes")

local definition = {
    id = "RING_SLAYING",
    name = "ring of slaying",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 6,
    stackable = false,
    -- Source: crawl-ref/source/item-prop-enum.h
    jewellery = {
        kind = jewellery_kinds.RING,
        -- Source: crawl-ref/source/item-prop.cc
        pluses = true,
        -- Source: crawl-ref/source/artefact.cc
        effects = {
            [capabilities.SLAYING] = magnitudes.ITEM_PLUS,
        },
    },

    -- Source: crawl-ref/source/item-name.cc
    -- ring of slaying has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "ring of slaying",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether ring of slaying enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
