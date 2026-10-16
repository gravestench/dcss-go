-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:936

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_RESISTANCE,
    name = "shield of Resistance",
    source_order = 61,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_KITE_SHIELD,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTRED",
    tile = "urand_resistance",
    tile_equipment = "kite_shield_of_resistance",
    type = "",
    flags = {
    },
    properties = {
        cold = 2,
        fire = 2,
        plus = 2,
        will = 2,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
