-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/art-data.txt:642

local categories = require("constants.catalog")
local artefact_ids = require("ids.artefacts")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = artefact_ids.UNRAND_PIERCER,
    name = "longbow \"Piercer\"",
    source_order = 37,
    class = classes.OBJ_WEAPONS,
    kind_id = item_ids.WPN_LONGBOW,
    fallback = "",
    brand = brands.PENETRATION,
    fallback_brand = "",
    appearance = "",
    inscription = "",
    description = "",
    brand_description = "",
    colour = "CYAN",
    tile = "urand_piercer",
    tile_equipment = "great_bow",
    type = "",
    flags = {
        "nogen",
    },
    properties = {
        ev = -2,
        plus = 7,
    },
    generation = {
        mode = "none",
    },
}

register.definition(categories.ARTEFACTS, definition)

return definition
