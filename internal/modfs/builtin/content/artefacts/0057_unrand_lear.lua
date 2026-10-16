-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:887

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_LEAR,
    name = "Lear's hauberk",
    source_order = 57,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_CHAIN_MAIL,
    fallback = {
        class = classes.OBJ_ARMOUR,
        kind_id = item_ids.ARM_PLATE_ARMOUR,
    },
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_GOLD",
    tile = "urand_lear",
    tile_equipment = "lears_hauberk",
    type = "",
    flags = {
        "special",
    },
    properties = {
        plus = 18,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 11,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
