-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1506

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local armour_egos = require("constants.armour_egos")

local definition = {
    id = artefact_ids.UNRAND_WARLOCK_MIRROR,
    name = "warlock's mirror",
    source_order = 110,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_BUCKLER,
    fallback = "",
    brand = armour_egos.REFLECTION,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description =
        "It can block and reflect piercing ranged attacks and magical attacks\nagainst the wielder's willpower.",
    brand_description = "",
    colour = "ETC_SILVER",
    tile = "urand_warlock",
    tile_equipment = "buckler_warlock",
    type = "",
    flags = {
    },
    properties = {
        plus = 3,
        value = 400,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
