-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:968

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_DRAGONMASK,
    name = "mask of the Dragon",
    source_order = 64,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_SHIMMER_BLUE",
    tile = "urand_dragonmask",
    tile_equipment = "art_dragonhelm",
    type = "",
    flags = {
        "seeinv",
    },
    properties = {
        slay = 3,
        will = 1,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
