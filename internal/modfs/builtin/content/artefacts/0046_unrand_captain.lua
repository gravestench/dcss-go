-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:761

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_CAPTAIN,
    name = "captain's cutlass",
    source_order = 46,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_RAPIER,
    fallback = "",
    brand = brands.SPEED,
    fallback_brand = "",
    appearance = "",
    inscription = "disarm",
    description = "",
    brand_description = "It may disarm weapon-wielding foes when striking them, dealing\nextra damage in the process.",
    colour = "DARKGREY",
    tile = "urand_cutlass",
    tile_equipment = "capt_cutlass",
    type = "cutlass",
    flags = {
    },
    properties = {
        plus = 7,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
