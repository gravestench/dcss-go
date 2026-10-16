-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1094

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_FOUR_WINDS,
    name = "amulet of the Four Winds",
    source_order = 75,
    class = classes.OBJ_JEWELLERY,
    kind_id = item_ids.AMU_NOTHING,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_POISON",
    tile = "urand_four_winds",
    tile_equipment = "",
    type = "",
    flags = {
        "clarity",
    },
    properties = {
        life = 1,
        will = 3,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
