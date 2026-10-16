-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1439

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_ETERNAL_TORMENT,
    name = "crown of Eternal Torment",
    source_order = 105,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_HAT,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "rTorment HP--",
    description = "",
    brand_description = "",
    colour = "ETC_DARK",
    tile = "urand_eternal_torment",
    tile_equipment = "eternal_torment",
    type = "",
    flags = {
        "evil",
        "seeinv",
        "nogen",
        "drain",
    },
    properties = {
        life = 3,
        plus = 3,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
