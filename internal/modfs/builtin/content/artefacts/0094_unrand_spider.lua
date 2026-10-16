-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1290

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_SPIDER,
    name = "boots of the spider",
    source_order = 94,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_BOOTS,
    fallback = "",
    brand = armour_egos.JUMPING,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "LIGHTMAGENTA",
    tile = "urand_spider",
    tile_equipment = "spider",
    type = "",
    flags = {
        "nogen",
    },
    properties = {
        plus = 3,
        stealth = 1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
