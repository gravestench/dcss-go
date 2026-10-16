-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:492

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_ZEPHYR,
    name = "longbow \"Zephyr\"",
    source_order = 25,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_LONGBOW,
    fallback = "",
    brand = brands.SPEED,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_GOLD",
    tile = "urand_zephyr",
    tile_equipment = "zephyr",
    type = "",
    flags = {
        "seeinv",
    },
    properties = {
        dex = 3,
        plus = 8,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
