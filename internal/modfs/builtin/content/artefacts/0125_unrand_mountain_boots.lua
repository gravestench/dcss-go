-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1678

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_MOUNTAIN_BOOTS,
    name = "mountain boots",
    source_order = 125,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_BOOTS,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "steadfast,",
    description = "",
    brand_description = "It prevents involuntary movement, except for blinking,\nteleportation, or banishment.",
    colour = "ETC_MOUNTAIN",
    tile = "urand_mountain",
    tile_equipment = "spider",
    type = "",
    flags = {
        "special",
    },
    properties = {
        cold = 1,
        plus = 3,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
