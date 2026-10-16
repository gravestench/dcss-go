-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:897

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_ZHOR,
    name = "skin of Zhor",
    source_order = 58,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ANIMAL_SKIN,
    fallback = {
        class = classes.OBJ_ARMOUR,
        kind_id = item_ids.ARM_STEAM_DRAGON_ARMOUR,
    },
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "*Englaciate",
    description = "It radiates cold, occasionally slowing all nearby creatures who are\nnot resistant to cold.",
    brand_description = "",
    colour = "BROWN",
    tile = "urand_zhor",
    tile_equipment = "zhor",
    type = "",
    flags = {
        "seeinv",
    },
    properties = {
        cold = 3,
        plus = 4,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
