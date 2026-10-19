-- ring of poison resistance (RING_POISON_RESISTANCE) belongs to
-- OBJ_JEWELLERY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local jewellery_kinds = require("constants.jewellery_kind")
local capabilities = require("constants.jewellery_capabilities")
local magnitudes = require("constants.jewellery_magnitudes")

local definition = {
    id = "RING_POISON_RESISTANCE",
    name = "ring of poison resistance",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 3,
    stackable = false,
    -- Source: crawl-ref/source/item-prop-enum.h
    jewellery = {
        kind = jewellery_kinds.RING,
        -- Source: crawl-ref/source/artefact.cc
        effects = {
            [capabilities.POISON_RESISTANCE] = 1,
        },
    },

    -- Source: crawl-ref/source/item-name.cc
    -- ring of poison resistance has its display text here so identification policy
    -- can choose known or unknown names consistently.
    naming = {
        text = "ring of poison resistance",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether ring of poison resistance enters
    -- random item pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
