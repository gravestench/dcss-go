-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:992

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_DRAGON_KING,
    name = "scales of the Dragon King",
    source_order = 66,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_GOLD_DRAGON_ARMOUR,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_GOLD",
    tile = "urand_dragon_king",
    tile_equipment = "dragonarm_gold",
    type = "",
    flags = {
    },
    properties = {
        plus = 9,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
