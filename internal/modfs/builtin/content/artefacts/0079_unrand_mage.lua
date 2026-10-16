-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1124

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_MAGE,
    name = "ring of the Mage",
    source_order = 79,
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.RING_WIZARDRY,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_ENCHANT",
    tile = "urand_mage",
    tile_equipment = "",
    type = "",
    flags = {
        "archmagi",
    },
    properties = {
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
