-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1064

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_AIR,
    name = "amulet of the Air",
    source_order = 72,
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_NOTHING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "Inacc Air",
    description = "It reduces the accuracy of all your attacks.\n+It enhances your air magic.",
    brand_description = "",
    colour = "ETC_ELECTRICITY",
    tile = "urand_air",
    tile_equipment = "",
    type = "",
    flags = {
        "elec",
        "fly",
        "rmsl",
    },
    properties = {
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
