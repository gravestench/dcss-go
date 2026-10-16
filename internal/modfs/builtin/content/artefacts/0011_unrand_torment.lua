-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:312

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_TORMENT,
    name = "sceptre of Torment",
    source_order = 11,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_EVENINGSTAR,
    fallback = "",
    brand = brands.PAIN,
    fallback_brand = "",
    appearance = "",
    inscription = "torment",
    description = "",
    brand_description = "It occasionally torments all nearby living foes when it strikes in\ncombat.",
    colour = "ETC_GOLD",
    tile = "spwpn_sceptre_of_torment",
    tile_equipment = "sceptre_of_torment",
    type = "",
    flags = {
        "evil",
    },
    properties = {
        plus = 7,
        value = 1200,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
