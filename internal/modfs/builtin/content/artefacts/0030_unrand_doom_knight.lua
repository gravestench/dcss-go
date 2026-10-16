-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:552

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_DOOM_KNIGHT,
    name = "sword of the Doom Knight",
    source_order = 30,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_GREAT_SWORD,
    fallback = "",
    brand = brands.PAIN,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "BLUE",
    tile = "urand_doom_knight",
    tile_equipment = "doom_knight",
    type = "",
    flags = {
        "nospell",
        "nogen",
    },
    properties = {
        plus = 13,
        will = 1,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
