-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:373

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_FAERIE,
    name = "faerie dragon scales",
    source_order = 16,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ACID_DRAGON_ARMOUR,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_JEWEL",
    tile = "urand_faerie",
    tile_equipment = "faerie_dragon_armour",
    type = "",
    flags = {
        "nogen",
        "no_upgrade",
    },
    properties = {
        plus = 3,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
