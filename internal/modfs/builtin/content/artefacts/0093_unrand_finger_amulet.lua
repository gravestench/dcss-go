-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1281

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_FINGER_AMULET,
    name = "macabre finger necklace",
    source_order = 93,
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_NOTHING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "It enables you to equip an extra ring.",
    brand_description = "",
    colour = "ETC_BONE",
    tile = "urand_finger",
    tile_equipment = "",
    type = "",
    flags = {
    },
    properties = {
        life = 1,
        value = 400,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
