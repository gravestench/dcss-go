-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1452

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")

local definition = {
    id = artefact_ids.UNRAND_VINES,
    name = "robe of Vines",
    source_order = 106,
    class = classes.OBJ_ARMOUR,
    kind_id = item_ids.ARM_ROBE,
    fallback = "",
    brand = "",
    fallback_brand = "",
    appearance = "",
    inscription = "NoPotionHeal",
    description = "Its wearer cannot be healed by potions.",
    brand_description = "",
    colour = "GREEN",
    tile = "urand_vines",
    tile_equipment = "vines",
    type = "",
    flags = {
    },
    properties = {
        plus = 1,
        regen = 4,
        value = 800,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
