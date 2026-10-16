-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1260

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_WOE,
    name = "Axe of Woe",
    source_order = 91,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_EXECUTIONERS_AXE,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_BLOOD",
    tile = "urand_axe_of_woe",
    tile_equipment = "axe_of_woe",
    type = "",
    flags = {
        "nogen",
        "no_upgrade",
    },
    properties = {
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
