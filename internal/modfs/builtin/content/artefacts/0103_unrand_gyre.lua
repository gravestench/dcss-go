-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:1414

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_GYRE,
    name = "pair of quick blades \"Gyre\" and \"Gimble\"",
    source_order = 103,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_QUICK_BLADE,
    fallback = "",
    brand = brands.PROTECTION,
    fallback_brand = brands.VORPAL,
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "ETC_ENCHANT",
    tile = "urand_gyre",
    tile_equipment = "gyre",
    type = "pair of quick blades",
    flags = {
    },
    properties = {
        plus = 12,
    },
    generation = {
        mode = "random",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
