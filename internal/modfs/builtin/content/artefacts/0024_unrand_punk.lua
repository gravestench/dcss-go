-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:479

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_PUNK,
    name = "greatsling \"Punk\"",
    source_order = 24,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_SLING,
    fallback = "",
    brand = brands.ACID,
    fallback_brand = brands.NORMAL,
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_SLIME",
    tile = "urand_punk",
    tile_equipment = "punk",
    type = "greatsling",
    flags = {
        "rCorr",
    },
    properties = {
        base_dam = 3,
        plus = 3,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
