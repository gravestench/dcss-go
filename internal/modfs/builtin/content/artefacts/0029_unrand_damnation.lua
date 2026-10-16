-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:539

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_DAMNATION,
    name = "arbalest \"Damnation\"",
    source_order = 29,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_ARBALEST,
    fallback = "",
    brand = "",
    fallback_brand = brands.FLAMING,
    appearance = "",
    inscription = "damnation",
    description = "",
    brand_description =
        "Any ammunition fired from it explodes in a burst of damnation on\nstriking a foe, dealing damage which byp" ..
        "asses armour.",
    colour = "ETC_FIRE",
    tile = "urand_damnation",
    tile_equipment = "crossbow_fire",
    type = "",
    flags = {
        "evil",
    },
    properties = {
        plus = 6,
        value = 800,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
