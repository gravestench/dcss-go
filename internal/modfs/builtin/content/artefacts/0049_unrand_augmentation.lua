-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:794

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_AUGMENTATION,
    name = "robe of Augmentation",
    source_order = 49,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ROBE,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTRED",
    tile = "urand_augmentation",
    tile_equipment = "robe_white_blue",
    type = "",
    flags = {
    },
    properties = {
        dex = 4,
        int = 4,
        plus = 4,
        str = 4,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 11,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
