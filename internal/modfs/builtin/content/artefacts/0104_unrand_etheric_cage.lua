-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1425

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_ETHERIC_CAGE,
    name = "Maxwell's etheric cage",
    source_order = 104,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HELMET,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "RegenMP+",
    description = "",
    brand_description = "",
    colour = "ETC_ELECTRICITY",
    tile = "urand_etheric_cage",
    tile_equipment = "etheric_cage",
    type = "",
    flags = {
        "mutate",
        "elec",
        "chaotic",
        "nogen",
    },
    properties = {
        mp = 4,
        plus = 0,
        value = 400,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
