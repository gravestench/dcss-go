-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1493

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_TALOS,
    name = "armour of Talos",
    source_order = 109,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_PLATE_ARMOUR,
    fallback = "",
    brand = armour_egos.PONDEROUSNESS,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_FIRE",
    tile = "urand_talos",
    tile_equipment = "talos",
    type = "",
    flags = {
        "nogen",
    },
    properties = {
        fire = 1,
        plus = 12,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
