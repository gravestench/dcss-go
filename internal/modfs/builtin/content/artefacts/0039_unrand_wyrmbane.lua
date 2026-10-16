-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:669

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_WYRMBANE,
    name = "lance \"Wyrmbane\"",
    source_order = 39,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_SPEAR,
    fallback = {
        class = classes.OBJ_WEAPONS,
        kind_id = item_ids.WPN_DEMON_TRIDENT,
    },
    brand = "",
    fallback_brand = brands.VORPAL,
    appearance = "",
    inscription = "slay drac,",
    description = "",
    brand_description = "It inflicts extra damage against dragons and draconians.",
    colour = "LIGHTGREEN",
    tile = "urand_wyrmbane",
    tile_equipment = "wyrmbane",
    type = "lance",
    flags = {
        "poison",
        "no_upgrade",
    },
    properties = {
        ac = 3,
        base_dam = 2,
        cold = 1,
        fire = 1,
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
