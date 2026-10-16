-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:817

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_BULLSEYE,
    name = "tower shield \"Bullseye\"",
    source_order = 51,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_TOWER_SHIELD,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "RED",
    tile = "urand_bullseye",
    tile_equipment = "kite_shield_bullseye",
    type = "",
    flags = {
        "nogen",
    },
    properties = {
        ev = -5,
        plus = 15,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
