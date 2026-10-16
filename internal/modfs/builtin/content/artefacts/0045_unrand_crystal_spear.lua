-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:748

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_CRYSTAL_SPEAR,
    name = "Lehudib's crystal spear",
    source_order = 45,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_SPEAR,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "GREEN",
    tile = "urand_crystal_spear",
    tile_equipment = "crystal_spear",
    type = "",
    flags = {
        "nogen",
    },
    properties = {
        int = 3,
        plus = 6,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
