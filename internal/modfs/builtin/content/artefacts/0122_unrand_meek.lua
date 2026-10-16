-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1645

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_MEEK,
    name = "staff of the Meek",
    source_order = 122,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_QUARTERSTAFF,
    fallback = "",
    brand = brands.PROTECTION,
    fallback_brand = "",
    appearance = "",
    inscription = "meekguard",
    description = "",
    brand_description = "It provides extra protection to wielders with little health.",
    colour = "WHITE",
    tile = "urand_meek",
    tile_equipment = "staff_mage_two",
    type = "",
    flags = {
    },
    properties = {
        plus = 7,
    },
    generation = {
        mode = "random",
        preferred_max_depth = 11,
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
