-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1386

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_ORANGE_CRYSTAL_PLATE_ARMOUR,
    name = "orange crystal plate armour",
    source_order = 101,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_CRYSTAL_PLATE_ARMOUR,
    fallback = "",
    brand = armour_egos.ARCHMAGI,
    fallback_brand = brands.NORMAL,
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTRED",
    tile = "urand_orange_crystal",
    tile_equipment = "orange_crystal",
    type = "",
    flags = {
        "clarity",
    },
    properties = {
        int = 3,
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
