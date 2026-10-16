-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:412

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_BRILLIANCE,
    name = "eveningstar \"Brilliance\"",
    source_order = 19,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_EVENINGSTAR,
    fallback = "",
    brand = brands.HOLY_WRATH,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_HOLY",
    tile = "urand_brilliance",
    tile_equipment = "mace_of_brilliance",
    type = "",
    flags = {
        "nogen",
    },
    properties = {
        ac = 5,
        int = 5,
        life = 1,
        plus = 1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
