-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1136

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_RCLOUDS,
    name = "robe of Clouds",
    source_order = 81,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ROBE,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "*Thunder rCloud",
    description =
        "It occasionally creates storm clouds above nearby enemies.\n+It grants its wearer immunity to clouds.",
    brand_description = "",
    colour = "ETC_MIST",
    tile = "urand_clouds",
    tile_equipment = "robe_clouds",
    type = "",
    flags = {
        "elec",
    },
    properties = {
        plus = 3,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
