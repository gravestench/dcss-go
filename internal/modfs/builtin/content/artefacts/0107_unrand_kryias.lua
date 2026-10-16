-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1464

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_KRYIAS,
    name = "Kryia's mail coat",
    source_order = 107,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_SCALE_MAIL,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "PotionHeal*2",
    description = "Potions are twice as effective at healing its wearer.",
    brand_description = "",
    colour = "LIGHTCYAN",
    tile = "urand_kryias",
    tile_equipment = "kryias",
    type = "",
    flags = {
    },
    properties = {
        cold = 1,
        plus = 7,
        value = 600,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 11,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
