-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1175

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_LIGHTNING_SCALES,
    name = "lightning scales",
    source_order = 84,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_BARDING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "swift,",
    description = "It allows the wearer to cover ground more swiftly.",
    brand_description = "",
    colour = "ETC_ELECTRICITY",
    tile = "urand_lightning_scales",
    tile_equipment = "lightning_scales",
    type = "",
    flags = {
        "elec",
    },
    properties = {
        plus = 6,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
