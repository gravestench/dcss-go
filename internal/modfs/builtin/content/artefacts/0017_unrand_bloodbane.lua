-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:384

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_BLOODBANE,
    name = "demon blade \"Bloodbane\"",
    source_order = 17,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_DEMON_BLADE,
    fallback = "",
    brand = brands.VORPAL,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_DARK",
    tile = "urand_bloodbane",
    tile_equipment = "bloodbane",
    type = "",
    flags = {
        "nogen",
    },
    properties = {
        angry = 5,
        plus = 8,
        stealth = -1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
