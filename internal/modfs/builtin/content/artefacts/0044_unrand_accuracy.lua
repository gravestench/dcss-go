-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:737

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_ACCURACY,
    name = "knife of Accuracy",
    source_order = 44,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DAGGER,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTCYAN",
    tile = "urand_knife_of_accuracy",
    tile_equipment = "knife_of_accuracy",
    type = "knife",
    flags = {
        "tilerim",
        "nogen",
    },
    properties = {
        plus = 27,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
